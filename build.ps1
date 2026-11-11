# Builds the manual.
#   default : out/anleitung-de.html, out/anleitung-en.html (images embedded, offline)
#   -Pdf    : additionally prints both pages to PDF with headless Chrome
#   -Web    : _site/ for GitHub Pages (images as files, index.html redirects to de/)
param([switch]$Pdf, [switch]$Web)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$langs = [ordered]@{
  de = @{ toc = 'Inhalt';   other = 'en'; otherLabel = 'English' }
  en = @{ toc = 'Contents'; other = 'de'; otherLabel = 'Deutsch' }
}

if ($Web) {
  $site = Join-Path $root '_site'
  if (Test-Path $site) { Remove-Item -Recurse -Force $site }
  New-Item -ItemType Directory -Force $site | Out-Null
  Copy-Item -Recurse (Join-Path $root 'bilder') (Join-Path $site 'bilder')
  Copy-Item (Join-Path $root 'tools/style.css') (Join-Path $site 'style.css')
  Set-Content -Encoding utf8 (Join-Path $site '.nojekyll') ''
  Set-Content -Encoding utf8 (Join-Path $site 'index.html') @'
<!doctype html><html lang="de"><head><meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=de/"><title>HD818 Anleitung</title></head>
<body><a href="de/">Deutsch</a> · <a href="en/">English</a></body></html>
'@
  foreach ($lang in $langs.Keys) {
    $l = $langs[$lang]
    $dir = Join-Path $site $lang
    New-Item -ItemType Directory -Force $dir | Out-Null
    $switch = Join-Path $site "lang-$lang.html"
    Set-Content -Encoding utf8 $switch "<div class=`"lang`"><a href=`"../$($l.other)/`">$($l.otherLabel)</a></div>"
    pandoc (Join-Path $root "$lang/README.md") `
      --from gfm+yaml_metadata_block --to html5 --standalone `
      --toc --toc-depth=2 --metadata toc-title=$($l.toc) `
      --css ../style.css `
      --include-before-body $switch --include-after-body (Join-Path $root 'tools/toc.html') `
      -o (Join-Path $dir 'index.html')
    Remove-Item $switch
    Write-Host "WEB:  $dir/index.html"
  }
  return
}

$out = Join-Path $root 'out'
New-Item -ItemType Directory -Force $out | Out-Null

foreach ($lang in $langs.Keys) {
  $l = $langs[$lang]
  $switch = Join-Path $out "lang-$lang.html"
  Set-Content -Encoding utf8 $switch "<div class=`"lang`"><a href=`"anleitung-$($l.other).html`">$($l.otherLabel)</a></div>"
  $html = Join-Path $out "anleitung-$lang.html"
  pandoc (Join-Path $root "$lang\README.md") `
    --from gfm+yaml_metadata_block --to html5 --standalone --embed-resources `
    --resource-path (Join-Path $root $lang) `
    --toc --toc-depth=2 --metadata toc-title=$($l.toc) `
    --css (Join-Path $root 'tools\style.css') `
    --include-before-body $switch --include-after-body (Join-Path $root 'tools/toc.html') `
    -o $html
  Remove-Item $switch
  Write-Host "HTML: $html"

  if ($Pdf) {
    $chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
                "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
                "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $chrome) { throw 'Chrome not found' }
    $pdfFile = Join-Path $out "anleitung-$lang.pdf"
    $uri = ([System.Uri]$html).AbsoluteUri
    & $chrome --headless=new --disable-gpu --no-pdf-header-footer --print-to-pdf="$pdfFile" $uri 2>$null | Out-Null
    Write-Host "PDF:  $pdfFile"
  }
}
