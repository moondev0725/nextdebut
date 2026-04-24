Add-Type -AssemblyName System.Windows.Forms

$ErrorActionPreference = "Stop"

function Find-ProjectRoot {
    if (-not [string]::IsNullOrWhiteSpace($env:NEXTDEBUT_HOME)) {
        $home = $env:NEXTDEBUT_HOME.Trim().Trim('"')
        $guiScript = Join-Path $home "tools\launch_nextdebut_gui.ps1"
        if (Test-Path -LiteralPath $guiScript) {
            return (Resolve-Path $home).Path
        }
    }

    $dir = $PSScriptRoot
    while ($dir) {
        $guiScript = Join-Path $dir "tools\launch_nextdebut_gui.ps1"
        if (Test-Path -LiteralPath $guiScript) {
            return $dir
        }

        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) {
            break
        }
        $dir = $parent
    }

    return $null
}

$root = Find-ProjectRoot
if (-not $root) {
    [System.Windows.Forms.MessageBox]::Show(
        "Cannot find tools\launch_nextdebut_gui.ps1.`nCheck the project root structure or set NEXTDEBUT_HOME to the project folder.",
        "NEXTDEBUT",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

$guiScript = Join-Path $root "tools\launch_nextdebut_gui.ps1"
$powershellExe = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"

Start-Process -FilePath $powershellExe -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Sta",
    "-WindowStyle", "Hidden",
    "-File", $guiScript
) -WorkingDirectory $root -WindowStyle Hidden -Wait:$false

exit 0
