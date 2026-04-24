param(
    [string]$BundleName = "NEXTDEBUT-Portable",
    [switch]$IncludeJre,
    [switch]$IncludePythonRuntime
)

$ErrorActionPreference = "Stop"

function Test-JdkRootLayout([string]$root) {
    if (-not $root) { return $false }
    $javaExe = Join-Path $root "bin\java.exe"
    $libDir = Join-Path $root "lib"
    if (-not ((Test-Path $javaExe) -and (Test-Path $libDir))) {
        return $false
    }
    $mods = Join-Path $libDir "modules"
    $cfg = Join-Path $libDir "jvm.cfg"
    return ((Test-Path $mods) -or (Test-Path $cfg))
}

function Resolve-JdkHomeRoot([string]$javaHome) {
    if (-not $javaHome) { return $null }
    $javaHome = ($javaHome.Trim() -replace '[\\/]+$', '')
    if (Test-JdkRootLayout $javaHome) {
        return (Resolve-Path $javaHome).Path
    }
    try {
        foreach ($dir in (Get-ChildItem $javaHome -Directory -ErrorAction SilentlyContinue)) {
            if ($dir.Name -like "jdk*" -and (Test-JdkRootLayout $dir.FullName)) {
                return $dir.FullName
            }
        }
    } catch {
    }
    return $null
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$distRoot = Join-Path $projectRoot "dist"
$bundleRoot = Join-Path $distRoot $BundleName
$runtimeRoot = Join-Path $bundleRoot "runtime"
$bundleJarPath = Join-Path $bundleRoot "nextdebut.jar"

# Default behavior: include JRE unless explicitly disabled in script.
$effectiveIncludeJre = $true
if ($PSBoundParameters.ContainsKey("IncludeJre")) {
    $effectiveIncludeJre = [bool]$IncludeJre
}

Write-Host "[portable] projectRoot: $projectRoot"
New-Item -ItemType Directory -Path $distRoot -Force | Out-Null
if (Test-Path $bundleRoot) {
    Remove-Item $bundleRoot -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $bundleRoot -Force | Out-Null

Write-Host "[portable] building spring boot jar..."
& (Join-Path $projectRoot "gradlew.bat") bootJar

$jar = Get-ChildItem (Join-Path $projectRoot "build\libs") -Filter "*.jar" |
    Where-Object { $_.Name -notlike "*-plain.jar" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $jar) {
    throw "bootJar output not found in build\libs"
}

Copy-Item $jar.FullName $bundleJarPath -Force
Write-Host "[portable] copied jar -> $bundleJarPath"

$copyItems = @(
    "python-ml",
    "assets",
    "tools",
    "NEXTDEBUT.bat"
)
foreach ($item in $copyItems) {
    $src = Join-Path $projectRoot $item
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $bundleRoot $item) -Recurse -Force
    }
}

if ($effectiveIncludeJre) {
    $resolvedHome = Resolve-JdkHomeRoot $env:JAVA_HOME
    if (-not $resolvedHome) {
        Write-Error "[portable] JAVA_HOME must point to a JDK root (folder containing bin\java.exe and lib\modules).`nCurrent JAVA_HOME='$($env:JAVA_HOME)' could not be resolved.`nExample: set JAVA_HOME=C:\Program Files\Java\jdk-21"
    }
    $jreTarget = Join-Path $runtimeRoot "jre"
    New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
    Copy-Item $resolvedHome $jreTarget -Recurse -Force
    if (-not (Test-JdkRootLayout $jreTarget)) {
        Write-Error "[portable] Bundled JDK layout looks invalid under: $jreTarget"
    }
    Write-Host "[portable] bundled JDK from $($resolvedHome) -> $jreTarget"
}

if ($IncludePythonRuntime.IsPresent) {
    $py = Get-Command python -ErrorAction SilentlyContinue
    if ($py -and $py.Path) {
        $pythonHome = & python -c "import sys; print(sys.base_prefix)"
        if (-not $pythonHome) {
            throw "Failed to resolve Python base_prefix."
        }
        $pythonHome = $pythonHome.Trim()
        if (-not (Test-Path (Join-Path $pythonHome "python.exe"))) {
            throw "Resolved Python home is invalid: $pythonHome"
        }
        $pyTarget = Join-Path $runtimeRoot "python"
        New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
        Copy-Item $pythonHome $pyTarget -Recurse -Force
        Write-Host "[portable] bundled python runtime -> $pyTarget"
        $pyExeBundled = Join-Path $pyTarget "python.exe"
        $req = Join-Path $bundleRoot "python-ml\requirements.txt"
        if ((Test-Path $pyExeBundled) -and (Test-Path $req)) {
            Write-Host "[portable] installing python-ml dependencies into bundle..."
            & $pyExeBundled -m pip install --disable-pip-version-check -r $req
            if ($LASTEXITCODE -ne 0) {
                throw "pip install failed for bundled python (exit $LASTEXITCODE)"
            }
        }
    } else {
        Write-Warning "[portable] python not found; skipped bundling python runtime"
    }
}

$readme = @"
NEXTDEBUT Portable Bundle

How to run:
1) Double-click NEXTDEBUT.bat (starts servers, opens browser; close window or use Stop to shut down)

Runtime resolution order:
- Python: runtime\python\python.exe -> system python -> py -3
- Java: runtime\jre\bin\java.exe -> system java
- Spring boot: nextdebut.jar (preferred) -> gradlew.bat bootRun (dev fallback)

If it does not start on another PC:
- Ensure this folder still contains runtime\jre and runtime\python (do not zip only part of the folder).
- Check logs\spring.log and logs\python-ml.log after launch.
- Ports 8000 and 8181 must be free (or use STOP SERVERS in the GUI launcher).
- Run tools\smoke_test_portable_bundle.ps1 on the target PC to verify.

Build requirements (on the machine that creates the zip):
- JAVA_HOME must resolve to JDK 21 root (folder with bin\java.exe and lib\modules). If JAVA_HOME points to e.g. C:\Program Files\Java, the script picks jdk-* under it.
- Python 3 must be available when using -IncludePythonRuntime.
"@
$readme | Out-File -FilePath (Join-Path $bundleRoot "PORTABLE_README.txt") -Encoding utf8

Write-Host "[portable] done: $bundleRoot"
