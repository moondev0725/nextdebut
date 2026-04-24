param(
    [string]$ProjectRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
} else {
    $ProjectRoot = $ProjectRoot.Trim('"')
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
}

$allowSystem = ($env:NEXTDEBUT_ALLOW_SYSTEM_RUNTIME -eq "1")
if ($allowSystem) {
    Write-Output "[NEXTDEBUT] NEXTDEBUT_ALLOW_SYSTEM_RUNTIME=1 -> skip runtime bootstrap."
    exit 0
}

$portablePy = Join-Path $ProjectRoot "runtime\python\python.exe"
$portableJava = Join-Path $ProjectRoot "runtime\jre\bin\java.exe"

function Resolve-PortableJavaExe([string]$projectRootPath) {
    $jreRoot = Join-Path $projectRootPath "runtime\jre"
    $direct = Join-Path $jreRoot "bin\java.exe"
    if (Test-Path $direct) {
        return $direct
    }
    if (-not (Test-Path $jreRoot)) {
        return $null
    }
    $candidate = Get-ChildItem -Path $jreRoot -Recurse -File -Filter java.exe -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match "\\bin\\java\.exe$" } |
        Select-Object -First 1
    if ($candidate) {
        return $candidate.FullName
    }
    return $null
}

if ((Test-Path $portablePy) -and (Resolve-PortableJavaExe $ProjectRoot)) {
    Write-Output "[NEXTDEBUT] Portable runtime already present."
    exit 0
}

$downloadDir = Join-Path $ProjectRoot "runtime\_downloads"
New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null

function Download-And-Extract([string]$url, [string]$zipPath, [string]$extractTo) {
    if ([string]::IsNullOrWhiteSpace($url)) {
        throw "Runtime download URL is empty."
    }
    Write-Output "[NEXTDEBUT] Downloading: $url"
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -TimeoutSec 600
    if (-not (Test-Path $zipPath)) {
        throw "Download failed: $zipPath"
    }
    Write-Output "[NEXTDEBUT] Extracting: $zipPath"
    New-Item -ItemType Directory -Path $extractTo -Force | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $extractTo -Force
}

function Download-File([string]$url, [string]$outFile) {
    if ([string]::IsNullOrWhiteSpace($url)) {
        throw "Runtime download URL is empty."
    }
    Write-Output "[NEXTDEBUT] Downloading: $url"
    Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing -TimeoutSec 600
    if (-not (Test-Path $outFile)) {
        throw "Download failed: $outFile"
    }
}

function New-DownloadPath([string]$baseName) {
    $safe = [System.Guid]::NewGuid().ToString("N")
    $name = [System.IO.Path]::GetFileNameWithoutExtension($baseName)
    $ext = [System.IO.Path]::GetExtension($baseName)
    if ([string]::IsNullOrWhiteSpace($ext)) {
        return (Join-Path $downloadDir ($baseName + "-" + $safe))
    }
    return (Join-Path $downloadDir ($name + "-" + $safe + $ext))
}

function Add-PathPrefix([string]$path) {
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path $path)) {
        return
    }
    $parts = @($env:PATH -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    foreach ($part in $parts) {
        if ($part.TrimEnd('\') -ieq $path.TrimEnd('\')) {
            return
        }
    }
    $env:PATH = "$path;$env:PATH"
}

function Get-FriendlyRuntimeErrorMessage([string]$rawMessage) {
    $m = [string]$rawMessage
    if ($m -match "timed out|name could not be resolved|connection|unable to connect|404|500|download") {
        return "런타임 다운로드에 실패했습니다. 인터넷 연결 또는 방화벽/프록시 설정을 확인해 주세요."
    }
    if ($m -match "Access is denied|권한|denied|administrator") {
        return "런타임 설치 권한이 부족합니다. 런처를 관리자 권한으로 실행해 주세요."
    }
    if ($m -match "There is not enough space|disk|space") {
        return "디스크 용량이 부족해 런타임 설치에 실패했습니다. 여유 공간을 확보해 주세요."
    }
    if ($m -match "Python installer failed") {
        return "Python 런타임 설치에 실패했습니다. 보안 프로그램 차단 여부를 확인한 뒤 다시 시도해 주세요."
    }
    if ($m -match "zip|archive|Expand-Archive") {
        return "Java 런타임 압축 해제에 실패했습니다. 다운로드 파일 손상 가능성이 있어 다시 시도해 주세요."
    }
    return "런타임 자동 설치에 실패했습니다. 잠시 후 다시 시도해 주세요."
}

try {
    $defaultPyInstallerUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
    $defaultJavaZipUrl = "https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse?project=jdk&archive_type=zip"

    if (-not (Test-Path $portablePy)) {
        $pyUrl = if ([string]::IsNullOrWhiteSpace($env:NEXTDEBUT_PY_RUNTIME_URL)) { $defaultPyInstallerUrl } else { $env:NEXTDEBUT_PY_RUNTIME_URL }
        $pyInstaller = New-DownloadPath "python-runtime-installer.exe"
        $pyTarget = Join-Path $ProjectRoot "runtime\python"
        Download-File $pyUrl $pyInstaller
        Write-Output "[NEXTDEBUT] Installing portable Python runtime..."
        $args = @(
            "/quiet",
            "InstallAllUsers=0",
            "Include_launcher=0",
            "PrependPath=0",
            "Include_pip=1",
            "Include_test=0",
            "SimpleInstall=1",
            "TargetDir=$pyTarget"
        )
        $p = Start-Process -FilePath $pyInstaller -ArgumentList $args -Wait -PassThru
        if ($p.ExitCode -ne 0) {
            throw "Python installer failed. exitCode=$($p.ExitCode)"
        }
    }

    if (-not (Resolve-PortableJavaExe $ProjectRoot)) {
        $javaUrl = if ([string]::IsNullOrWhiteSpace($env:NEXTDEBUT_JAVA_RUNTIME_URL)) { $defaultJavaZipUrl } else { $env:NEXTDEBUT_JAVA_RUNTIME_URL }
        $javaZip = New-DownloadPath "java-runtime.zip"
        $javaTarget = Join-Path $ProjectRoot "runtime\jre"
        Download-And-Extract $javaUrl $javaZip $javaTarget
    }

    if (Test-Path $portablePy) {
        $requirementsPath = Join-Path $ProjectRoot "python-ml\requirements.txt"
        if (Test-Path $requirementsPath) {
            Write-Output "[NEXTDEBUT] Installing Python dependencies..."
            Add-PathPrefix (Join-Path (Split-Path $portablePy -Parent) "Scripts")
            & $portablePy -m pip install --disable-pip-version-check --no-warn-script-location --upgrade pip
            & $portablePy -m pip install --disable-pip-version-check --no-warn-script-location -r $requirementsPath
        }
    }
} catch {
    $raw = [string]$_.Exception.Message
    Write-Output ("[NEXTDEBUT] Runtime bootstrap failed: " + $raw)
    Write-Output ("[NEXTDEBUT] " + (Get-FriendlyRuntimeErrorMessage $raw))
    exit 1
}

if (-not (Test-Path $portablePy)) {
    Write-Output "[NEXTDEBUT] Portable Python missing after bootstrap: runtime\python\python.exe"
    exit 1
}
if (-not (Resolve-PortableJavaExe $ProjectRoot)) {
    Write-Output "[NEXTDEBUT] Portable Java missing after bootstrap: runtime\jre\bin\java.exe (or runtime\jre\jdk*\bin\java.exe)"
    exit 1
}

Write-Output "[NEXTDEBUT] Runtime bootstrap complete."
exit 0
