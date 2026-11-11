# Builds both manuals (user manual + installation manual) in DE and EN.
#   default : out/   – same folder layout as the website, images embedded (works offline)
#   -Pdf    : additionally prints every page to out/*.pdf with headless Chrome
#   -Web    : _site/ for GitHub Pages (images as files)
param([switch]$Pdf, [switch]$Web)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$dest = if ($Web) { Join-Path $root '_site' } else { Join-Path $root 'out' }

# path = source folder and site folder; up = "../" count back to the site root
$docs = @(
  @{ id = 'anleitung'; path = '';          up = '../';    other = 'hardware/'; label = @{ de = 'Montageanleitung'; en = 'Installation manual' } }
  @{ id = 'montage';   path = 'hardware/'; up = '../../'; other = '';          label = @{ de = 'Benutzeranleitung'; en = 'User manual' } }
)
$langs = @{
  de = @{ toc = 'Inhalt';   other = 'en'; otherLabel = 'English' }
  en = @{ toc = 'Contents'; other = 'de'; otherLabel = 'Deutsch' }
}

if (Test-Path $dest) { Get-ChildItem $dest -Exclude *.pdf | Remove-Item -Recurse -Force }
New-Item -ItemType Directory -Force $dest | Out-Null
if ($Web) {
  Copy-Item -Recurse (Join-Path $root 'bilder') (Join-Path $dest 'bilder')
  Copy-Item (Join-Path $root 'tools/style.css') (Join-Path $dest 'style.css')
  Copy-Item (Join-Path $root 'tools/style-hw.css') (Join-Path $dest 'style-hw.css')
  Set-Content -Encoding utf8 (Join-Path $dest '.nojekyll') ''
}
Copy-Item (Join-Path $root 'tools/index.html') (Join-Path $dest 'index.html')

$chrome = $null
if ($Pdf) {
  $chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
              "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
              "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $chrome) { throw 'Chrome not found' }
}

foreach ($d in $docs) {
  foreach ($lang in 'de', 'en') {
    $l = $langs[$lang]
    $src = Join-Path $root "$($d.path)$lang"
    $dir = Join-Path $dest "$($d.path)$lang"
    New-Item -ItemType Directory -Force $dir | Out-Null

    # top-right links: other language + the other manual
    $otherDoc = "$($d.up)$($d.other)$lang/"
    $switch = Join-Path $dest "switch-$($d.id)-$lang.html"
    Set-Content -Encoding utf8 $switch ("<div class=`"lang`"><a href=`"../$($l.other)/`">$($l.otherLabel)</a> · " +
      "<a href=`"$otherDoc`">$($d.label[$lang])</a></div>")

    $args = @((Join-Path $src 'README.md'),
      '--from', 'gfm+yaml_metadata_block', '--to', 'html5', '--standalone',
      '--toc', '--toc-depth=2', '--metadata', "toc-title=$($l.toc)",
      '--include-before-body', $switch,
      '--include-after-body', (Join-Path $root 'tools/toc.html'),
      '-o', (Join-Path $dir 'index.html'))
    if ($Web) { $args += @('--css', "$($d.up)style.css"); if ($d.id -eq 'montage') { $args += @('--css', "$($d.up)style-hw.css") } }
    else      { $args += @('--embed-resources', '--resource-path', $src, '--css', (Join-Path $root 'tools/style.css'))
                if ($d.id -eq 'montage') { $args += @('--css', (Join-Path $root 'tools/style-hw.css')) } }
    pandoc @args
    Remove-Item $switch
    Write-Host "HTML: $dir/index.html"

    if ($Pdf) {
      $pdfFile = Join-Path $dest "$($d.id)-$lang.pdf"
      $uri = ([System.Uri](Join-Path $dir 'index.html')).AbsoluteUri
      & $chrome --headless=new --disable-gpu --no-pdf-header-footer --print-to-pdf="$pdfFile" $uri 2>$null | Out-Null
      Write-Host "PDF:  $pdfFile"
    }
  }
}
