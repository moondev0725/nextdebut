$ErrorActionPreference = "Stop"

# 스크립트 위치 기준으로 프로젝트 루트 (이 스크립트가 tools\ 에 있음)
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$launcherBat = Join-Path $projectRoot "NEXTDEBUT.bat"
$silentLauncher = Join-Path $projectRoot "launcher\RUN_NEXTDEBUT_SILENT.vbs"
$launcherPs = Join-Path $projectRoot "tools\Launch_NEXTDEBUT.ps1"
$guiScript = Join-Path $projectRoot "tools\launch_nextdebut_gui.ps1"
$powershellExe = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"

$desktopCandidates = @(
    [Environment]::GetFolderPath("Desktop"),
    (Join-Path $env:USERPROFILE "Desktop")
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

if (-not (Test-Path $launcherBat)) {
    throw "NEXTDEBUT.bat 없음: $launcherBat"
}
if (-not (Test-Path $silentLauncher)) {
    throw "RUN_NEXTDEBUT_SILENT.vbs 없음: $silentLauncher"
}
if (-not (Test-Path $launcherPs)) {
    throw "Launch_NEXTDEBUT.ps1 없음: $launcherPs"
}
if (-not (Test-Path $guiScript)) {
    throw "GUI 스크립트 없음: $guiScript"
}

$wsh = New-Object -ComObject WScript.Shell

$iconCandidates = @(
    (Join-Path $projectRoot "assets\nextdebut.ico"),
    (Join-Path $projectRoot "icon.ico"),
    (Join-Path $projectRoot "src\main\resources\static\favicon.ico")
)

$iconLocation = $null
foreach ($icon in $iconCandidates) {
    if (Test-Path $icon) {
        $iconLocation = "$icon,0"
        break
    }
}

if (-not $desktopCandidates -or $desktopCandidates.Count -eq 0) {
    throw "바탕화면 경로를 찾을 수 없습니다."
}

# 바로가기는 wscript.exe → launcher\RUN_NEXTDEBUT_SILENT.vbs 로 통일
$wscriptExe = Join-Path $env:WINDIR "System32\wscript.exe"
$shortcutArgs = "`"$silentLauncher`""

foreach ($desktopPath in $desktopCandidates) {
    $launcherShortcutPath = Join-Path $desktopPath "NEXTDEBUT.lnk"
    $launcherShortcut = $wsh.CreateShortcut($launcherShortcutPath)
    $launcherShortcut.TargetPath = $wscriptExe
    $launcherShortcut.Arguments = $shortcutArgs
    $launcherShortcut.WorkingDirectory = $projectRoot
    $launcherShortcut.Description = "NEXTDEBUT — 프로젝트 폴더 옮긴 뒤에는 이 스크립트를 다시 실행해 바로가기를 갱신하세요."
    $launcherShortcut.WindowStyle = 7
    if ($iconLocation) { $launcherShortcut.IconLocation = $iconLocation }
    $launcherShortcut.Save()
    Write-Output "바로가기 생성: $launcherShortcutPath"
}

$oldShortcuts = @(
    (Join-Path ([Environment]::GetFolderPath("Desktop")) "NEXTDEBUT Launcher.lnk"),
    (Join-Path ([Environment]::GetFolderPath("Desktop")) "NEXTDEBUT Launcher (Silent).lnk"),
    (Join-Path ([Environment]::GetFolderPath("Desktop")) "NEXTDEBUT Launcher (Console).lnk"),
    (Join-Path (Join-Path $env:USERPROFILE "Desktop") "NEXTDEBUT Launcher.lnk"),
    (Join-Path (Join-Path $env:USERPROFILE "Desktop") "NEXTDEBUT Launcher (Silent).lnk"),
    (Join-Path (Join-Path $env:USERPROFILE "Desktop") "NEXTDEBUT Launcher (Console).lnk"),
    (Join-Path $projectRoot "NEXTDEBUT Launcher (user).lnk"),
    (Join-Path $projectRoot "NEXTDEBUT Launcher (Console).lnk")
)
foreach ($old in $oldShortcuts) {
    if (Test-Path $old) {
        Remove-Item $old -Force -ErrorAction SilentlyContinue
    }
}
