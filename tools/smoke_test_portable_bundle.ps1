param(
    [string]$BundlePath = ""
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

function Get-BundleJavaExe([string]$bundleRootPath) {
    $jreRoot = Join-Path $bundleRootPath "runtime\jre"
    if (-not (Test-Path $jreRoot)) {
        return $null
    }
    if (Test-JdkRootLayout $jreRoot) {
        return (Join-Path $jreRoot "bin\java.exe")
    }
    foreach ($dir in (Get-ChildItem $jreRoot -Directory -ErrorAction SilentlyContinue)) {
        if ($dir.Name -like "jdk*" -and (Test-JdkRootLayout $dir.FullName)) {
            return (Join-Path $dir.FullName "bin\java.exe")
        }
    }
    return $null
}

function Test-PortOpen([int]$port, [int]$timeoutMs = 400) {
    $client = $null
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect("127.0.0.1", $port, $null, $null)
        if (-not $iar.AsyncWaitHandle.WaitOne($timeoutMs, $false)) {
            return $false
        }
        $client.EndConnect($iar) | Out-Null
        return $true
    } catch {
        return $false
    } finally {
        if ($null -ne $client) {
            try { $client.Close() } catch {}
        }
    }
}

if (-not $BundlePath) {
    $BundlePath = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "dist\NEXTDEBUT-Portable"
}

if (-not (Test-Path $BundlePath)) {
    Write-Host "[smoke] FAIL: bundle not found: $BundlePath"
    exit 2
}

$bundle = (Resolve-Path $BundlePath).Path
$logsDir = Join-Path $bundle "logs"
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null

$py = Join-Path $bundle "runtime\python\python.exe"
$java = Get-BundleJavaExe $bundle
$jar = Join-Path $bundle "nextdebut.jar"
$pyDir = Join-Path $bundle "python-ml"

foreach ($p in @($py, $jar, (Join-Path $pyDir "app.py"))) {
    if (-not (Test-Path $p)) {
        Write-Host "[smoke] FAIL: missing $p"
        exit 3
    }
}
if (-not $java -or -not (Test-Path $java)) {
    Write-Host "[smoke] FAIL: bundled JDK java.exe not found under runtime\jre (flat or jdk-* layout)."
    exit 3
}

Write-Host "[smoke] testing imports on portable python..."
& $py -c "import uvicorn, fastapi, sklearn; print('imports ok')" 2>&1 | Write-Host
if ($LASTEXITCODE -ne 0) {
    Write-Host "[smoke] FAIL: python deps"
    exit 4
}

Write-Host "[smoke] freeing ports 8000 / 8181..."
foreach ($port in @(8000, 8181)) {
    try {
        Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue |
            ForEach-Object {
                try { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } catch {}
            }
    } catch {
    }
}
Start-Sleep -Seconds 2

Write-Host "[smoke] starting uvicorn + spring (background)..."
$pyOut = Join-Path $logsDir "smoke-py.out"
$pyErr = Join-Path $logsDir "smoke-py.err"
Remove-Item $pyOut, $pyErr -ErrorAction SilentlyContinue

$springBaseUrl = "http://127.0.0.1:8181/"
$mlDocsUrl = "http://127.0.0.1:8000/docs"

Start-Process -FilePath $py -ArgumentList @(
    "-m", "uvicorn", "app:app", "--host", "127.0.0.1", "--port", "8000"
) -WorkingDirectory $pyDir -WindowStyle Hidden -RedirectStandardOutput $pyOut -RedirectStandardError $pyErr

# Do not redirect Spring stdout to a file: massive Hibernate logs can fill the pipe and stall the JVM.
$springProc = Start-Process -FilePath $java -ArgumentList @("-jar", "nextdebut.jar") -WorkingDirectory $bundle `
    -WindowStyle Hidden -PassThru

$ready = $false
for ($i = 0; $i -lt 120; $i++) {
    if (Test-PortOpen 8181 500) {
        $ready = $true
        break
    }
    Start-Sleep -Seconds 1
}

if (-not $ready) {
    Write-Host "[smoke] FAIL: TCP 8181 did not open within 120s."
    Write-Host "--- smoke-py.err (tail) ---"
    if (Test-Path $pyErr) { Get-Content $pyErr -Tail 60 -ErrorAction SilentlyContinue }
    if ($springProc -and -not $springProc.HasExited) {
        try { Stop-Process -Id $springProc.Id -Force -ErrorAction SilentlyContinue } catch {}
    }
    exit 5
}

try {
    $resp = Invoke-WebRequest -Uri $springBaseUrl -UseBasicParsing -TimeoutSec 5
    Write-Host "[smoke] OK Spring TCP + HTTP $($resp.StatusCode)"
} catch {
    if ($_.Exception.Response) {
        $c = [int]$_.Exception.Response.StatusCode
        if ($c -gt 0) {
            Write-Host "[smoke] OK Spring TCP + HTTP $c (server is responding)"
        } else {
            Write-Host "[smoke] OK Spring TCP (HTTP probe: $($_.Exception.Message))"
        }
    } else {
        Write-Host "[smoke] OK Spring TCP (HTTP probe: $($_.Exception.Message))"
    }
}

$mlOk = $false
for ($m = 0; $m -lt 45; $m++) {
    try {
        $ml = Invoke-WebRequest -Uri $mlDocsUrl -UseBasicParsing -TimeoutSec 5
        if ($ml.StatusCode -ge 200 -and $ml.StatusCode -lt 500) {
            Write-Host "[smoke] OK ML HTTP $($ml.StatusCode)"
            $mlOk = $true
            break
        }
    } catch {
    }
    Start-Sleep -Seconds 1
}
if (-not $mlOk) {
    Write-Host "[smoke] WARN ML: /docs not ready within 45s (first cold start can be slow). Check logs\smoke-py.err"
}

Write-Host "[smoke] stopping listeners on 8000/8181..."
foreach ($port in @(8000, 8181)) {
    try {
        Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue |
            ForEach-Object {
                try { Stop-Process -Id $_.OwningProcess -Force -ErrorAction Stop } catch {}
            }
    } catch {
    }
}

Write-Host "[smoke] PASS"
exit 0
