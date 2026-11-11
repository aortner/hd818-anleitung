# Builds the manual: out/anleitung-de.html, out/anleitung-en.html (images embedded).
# -Pdf additionally prints both pages to PDF with headless Chrome.
param([switch]$Pdf)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$out = Join-Path $root 'out'
New-Item -ItemType Directory -Force $out | Out-Null

$langs = @{
  de = @{ toc = 'Inhalt';   other = 'en'; otherLabel = 'English' }
  en = @{ toc = 'Contents'; other = 'de'; otherLabel = 'Deutsch' }
}

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
    --include-before-body $switch `
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
