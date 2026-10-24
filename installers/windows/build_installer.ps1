<#
.SYNOPSIS
    Builds the Flutter release binary and packages the Windows Inno Setup installer.
#>
param (
    [string]$InnoCompiler = "C:\Program Files\Inno Setup 7\iscc.exe"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\..\.."

Write-Host "==> [1/4] Regenerating branding assets and icons..." -ForegroundColor Cyan
python "$ProjectRoot\tools\generate_icons.py"

Write-Host "==> [2/4] Building Flutter Windows Release..." -ForegroundColor Cyan
Set-Location $ProjectRoot
flutter build windows --release

Write-Host "==> [3/4] Checking Inno Setup Compiler..." -ForegroundColor Cyan
if (-not (Test-Path $InnoCompiler)) {
    # Check alternate Program Files (x86)
    $InnoCompiler = "C:\Program Files (x86)\Inno Setup 6\iscc.exe"
}
if (-not (Test-Path $InnoCompiler)) {
    Write-Error "Inno Setup compiler not found. Please verify Inno Setup installation."
    exit 1
}

Write-Host "Found Inno Setup at: $InnoCompiler" -ForegroundColor Green

Write-Host "==> [4/4] Compiling Windows Installer..." -ForegroundColor Cyan
& $InnoCompiler "$ScriptDir\gitora_setup.iss"

Write-Host "==> Windows installer built successfully in dist/" -ForegroundColor Green
Get-Item "$ProjectRoot\dist\*.exe" | Select-Object Name, Length, LastWriteTime
