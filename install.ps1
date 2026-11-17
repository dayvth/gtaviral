# Instalador do GTAVIral para Windows 10/11 (64 bits). Uso, no PowerShell:
#   irm https://raw.githubusercontent.com/dayvth/gtaviral/main/install.ps1 | iex
# Voz local grátis (Chatterbox, ~3 GB a mais):
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/dayvth/gtaviral/main/install.ps1))) -VozLocal
param([switch]$VozLocal, [switch]$SemApp)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"   # downloads muito mais rápidos no PowerShell 5
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo = "dayvth/gtaviral"
$Rel = if ($env:GTAVIRAL_REL) { $env:GTAVIRAL_REL } else { "https://github.com/$Repo/releases/latest/download" }
$Data = Join-Path $env:APPDATA "GTAVIral"
$FfVer = "b6.1.1"
$FfmpegSha = "04e1307997530f9cf2fe35cba2ca7e8875ca91da02f89d6c7243df819c94ad00"
$FfprobeSha = "3a7e2dc003dc2cd1472827e4c7c4f056ae1ae0ae7c5bbc580c99b49827351ba4"

function Passo($t) { Write-Host "`n> $t" -ForegroundColor Magenta }
function Ok($t) { Write-Host "  OK $t" -ForegroundColor Green }
function Falha($t) { Write-Host "`nX $t" -ForegroundColor Red; exit 1 }
function Baixar($url, $dest) { Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $dest }
function Sha($f) { (Get-FileHash -Algorithm SHA256 $f).Hash.ToLower() }
function Gunzip($src, $dst) {
  $in = [IO.File]::OpenRead($src); $gz = New-Object IO.Compression.GZipStream($in, [IO.Compression.CompressionMode]::Decompress)
  $out = [IO.File]::Create($dst); $gz.CopyTo($out); $out.Close(); $gz.Close(); $in.Close()
}
function Confere($sums, $nome, $arquivo) {
  $linha = (Get-Content $sums | Where-Object { $_ -match " $([regex]::Escape($nome))$" }) | Select-Object -First 1
  if (-not $linha) { return $false }
  return ($linha.Split(" ")[0].ToLower() -eq (Sha $arquivo))
}

Write-Host "`n  GTAVIral - instalacao para Windows`n" -ForegroundColor Magenta
if (-not [Environment]::Is64BitOperatingSystem) { Falha "O GTAVIral precisa do Windows 10 ou 11 de 64 bits." }
if ([Environment]::OSVersion.Version.Major -lt 10) { Falha "O GTAVIral precisa do Windows 10 ou 11." }
$livre = [math]::Floor((Get-PSDrive -Name ($env:SystemDrive.TrimEnd(":"))).Free / 1GB)
if ($livre -lt 15) { Falha "Pouco espaco livre ($livre GB). Libere pelo menos 15 GB e rode de novo." }
New-Item -ItemType Directory -Force -Path (Join-Path $Data "bin") | Out-Null
$Tmp = Join-Path ([IO.Path]::GetTempPath()) ("gtaviral-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null

try {
  Passo "1/5 - Gerenciador do motor (uv)"
  $Uv = @("$env:USERPROFILE\.local\bin\uv.exe", "$env:USERPROFILE\.cargo\bin\uv.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $Uv) { $c = Get-Command uv -ErrorAction SilentlyContinue; if ($c) { $Uv = $c.Source } }
  if (-not $Uv) {
    $env:UV_NO_MODIFY_PATH = "1"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://astral.sh/uv/install.ps1 | iex" | Out-Null
    $Uv = "$env:USERPROFILE\.local\bin\uv.exe"
  }
  if (-not (Test-Path $Uv)) { Falha "Nao consegui instalar o uv. Verifique a internet e rode de novo." }
  Ok "uv pronto"

  Passo "2/5 - FFmpeg (edicao de video)"
  foreach ($b in @(@("ffmpeg", $FfmpegSha), @("ffprobe", $FfprobeSha))) {
    $gz = Join-Path $Tmp "$($b[0]).gz"; $exe = Join-Path $Tmp "$($b[0]).exe"
    Baixar "https://github.com/eugeneware/ffmpeg-static/releases/download/$FfVer/$($b[0])-win32-x64.gz" $gz
    Gunzip $gz $exe
    if ((Sha $exe) -ne $b[1]) { Falha "O FFmpeg baixado nao confere (download corrompido). Rode de novo." }
    Copy-Item $exe (Join-Path $Data "bin\$($b[0]).exe") -Force
  }
  Ok "FFmpeg instalado"

  Passo "3/5 - Motor do GTAVIral"
  $Sums = Join-Path $Tmp "SHA256SUMS"; Baixar "$Rel/SHA256SUMS" $Sums
  $Tgz = Join-Path $Tmp "gtaviral-engine.tar.gz"; Baixar "$Rel/gtaviral-engine.tar.gz" $Tgz
  if (-not (Confere $Sums "gtaviral-engine.tar.gz" $Tgz)) { Falha "O motor baixado nao confere. Rode de novo." }
  $New = Join-Path $Data "engine.new"; if (Test-Path $New) { Remove-Item $New -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $New | Out-Null
  tar -xzf $Tgz -C $New
  $Old = Join-Path $Data "engine"
  if (Test-Path (Join-Path $Old "tts_worker\.venv")) { Move-Item (Join-Path $Old "tts_worker\.venv") (Join-Path $New "tts_worker\.venv") }
  if (Test-Path $Old) { Remove-Item $Old -Recurse -Force }
  Move-Item $New $Old
  Write-Host "  preparando o Python do motor (primeira vez leva alguns minutos)..."
  $env:PYTHONUTF8 = "1"
  & $Uv sync --project $Old --python 3.11 -q
  if ($LASTEXITCODE -ne 0) { Falha "Falha ao preparar o motor. Rode de novo; se repetir, veja a secao Problemas do guia." }
  Ok "motor pronto"

  Passo "4/5 - Voz local gratis (opcional)"
  if ($VozLocal) {
    & $Uv sync --project (Join-Path $Old "tts_worker") --python 3.11 -q
    if ($LASTEXITCODE -eq 0) { Ok "voz local instalada" } else { Write-Host "  aviso: a voz local nao instalou; o app usa a voz rapida (Kokoro) ou a ElevenLabs." }
  } else { Write-Host "  pulado (use -VozLocal para instalar; com ElevenLabs nao precisa)" }

  Passo "5/5 - Aplicativo"
  if ($SemApp) { Write-Host "  pulado (-SemApp)" } else {
    $Setup = Join-Path $Tmp "GTAVIral-windows-x64-setup.exe"
    Baixar "$Rel/GTAVIral-windows-x64-setup.exe" $Setup
    if (-not (Confere $Sums "GTAVIral-windows-x64-setup.exe" $Setup)) { Falha "O aplicativo baixado nao confere. Rode de novo." }
    Get-Process gtaviral -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Process -FilePath $Setup -ArgumentList "/S" -Wait
    Ok "GTAVIral instalado"
  }
} finally {
  Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`nPronto! Abra o GTAVIral pelo menu Iniciar. Na primeira abertura ele baixa os modelos de IA." -ForegroundColor Green
if (-not $SemApp) {
  $App = @("$env:LOCALAPPDATA\GTAVIral\gtaviral.exe", "$env:ProgramFiles\GTAVIral\gtaviral.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($App) { Start-Process $App }
}
