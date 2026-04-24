$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$powershellExe = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
$launcherPs = Join-Path $projectRoot "tools\Launch_NEXTDEBUT.ps1"
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "NEXTDEBUT.lnk"

if (-not (Test-Path $launcherPs)) {
    throw "Launch_NEXTDEBUT.ps1 없음: $launcherPs"
}

$args = "-NoProfile -ExecutionPolicy Bypass -Sta -WindowStyle Hidden -File `"$launcherPs`""

$wsh = New-Object -ComObject WScript.Shell
$sc = $wsh.CreateShortcut($shortcutPath)
$sc.TargetPath = $powershellExe
$sc.Arguments = $args
$sc.WorkingDirectory = $projectRoot
$sc.Description = "NEXTDEBUT"
$sc.WindowStyle = 7
$iconPath = Join-Path $projectRoot "assets\nextdebut.ico"
if (Test-Path $iconPath) {
    $sc.IconLocation = "$iconPath,0"
}
$sc.Save()

Write-Output "바로가기 저장: $shortcutPath"
