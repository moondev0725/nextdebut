$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$pyDir = Join-Path $projectRoot "python-ml"
$logsDir = Join-Path $projectRoot "logs"
$springLog = Join-Path $logsDir "spring.log"
$pythonLog = Join-Path $logsDir "python-ml.log"
$launcherLog = Join-Path $logsDir "launcher-gui.log"
$pythonConsoleScript = Join-Path $logsDir "run-python-console.cmd"
$springConsoleScript = Join-Path $logsDir "run-spring-console.cmd"
$pythonConsolePidFile = Join-Path $logsDir "python-console.pid"
$springConsolePidFile = Join-Path $logsDir "spring-console.pid"
$userUrl = "http://127.0.0.1:8181/"
$iconPath = Join-Path $projectRoot "assets\nextdebut.ico"
$portablePythonPath = Join-Path $projectRoot "runtime\python\python.exe"
$ensureRuntimeScript = Join-Path $projectRoot "tools\ensure_runtime.ps1"
$appJarPath = Join-Path $projectRoot "nextdebut.jar"
if (-not (Test-Path $appJarPath)) {
    $appJarPath = Join-Path $projectRoot "nextdebut.jar"
}
$script:serverStatus = "OFF"
$script:isBooting = $false

# Prevent duplicate launcher windows.
$createdNewMutex = $false
$launcherMutex = New-Object System.Threading.Mutex($true, "Local\NextDebutLauncherGuiMutex", [ref]$createdNewMutex)
if (-not $createdNewMutex) {
    [System.Windows.Forms.MessageBox]::Show(
        "런처가 이미 실행 중입니다.",
        "NEXTDEBUT",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
    exit 0
}

New-Item -ItemType Directory -Path $logsDir -Force | Out-Null

function Write-LauncherLog([string]$msg) {
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg" | Out-File -FilePath $launcherLog -Encoding utf8 -Append
}

function Write-ConsoleScript([string]$path, [string[]]$lines) {
    $content = @("@echo off") + $lines
    [System.IO.File]::WriteAllLines($path, $content, [System.Text.Encoding]::ASCII)
}

function Save-PidFile([string]$path, $process) {
    if (-not $process) { return }
    try {
        [System.IO.File]::WriteAllText($path, [string]$process.Id, [System.Text.Encoding]::ASCII)
    } catch {
    }
}

function Read-PidFile([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    try {
        $raw = (Get-Content -Path $path -Raw -ErrorAction Stop).Trim()
        $pidValue = 0
        if ([int]::TryParse($raw, [ref]$pidValue) -and $pidValue -gt 0) {
            return $pidValue
        }
    } catch {
    }
    return $null
}

function Clear-PidFile([string]$path) {
    try {
        if (Test-Path $path) {
            Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
        }
    } catch {
    }
}

function Show-Info([string]$msg) {
    [System.Windows.Forms.MessageBox]::Show(
        $msg,
        "NEXTDEBUT",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
}

function Show-Error([string]$msg) {
    [System.Windows.Forms.MessageBox]::Show(
        $msg,
        "NEXTDEBUT",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
}

function Get-LauncherIcon {
    if (-not (Test-Path $iconPath)) {
        return $null
    }
    try {
        return New-Object System.Drawing.Icon($iconPath)
    } catch {
        return $null
    }
}

function New-ProgressForm([string]$titleText) {
    $xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="NEXTDEBUT"
        Width="520" Height="230"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        AllowsTransparency="True"
        ResizeMode="NoResize"
        Background="Transparent"
        Topmost="True"
        FontFamily="Segoe UI">
    <Border Background="#101827" CornerRadius="8" BorderBrush="#26324A" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="42"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Grid x:Name="ProgressTitleBar" Grid.Row="0" Background="#121C2D">
                <StackPanel Orientation="Horizontal" Margin="18,0,0,0" VerticalAlignment="Center">
                    <Border Width="18" Height="18" CornerRadius="5" Background="#B858F0" Margin="0,0,9,0">
                        <TextBlock Text="▶" Foreground="White" FontSize="9" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="1,0,0,0"/>
                    </Border>
                    <TextBlock Text="NEXTDEBUT" Foreground="#EAF0FF" FontFamily="Segoe UI Semibold" FontSize="13" VerticalAlignment="Center"/>
                </StackPanel>
            </Grid>

            <Grid Grid.Row="1" Margin="30,24,30,28">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="18"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="22"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <TextBlock x:Name="ProgressTitle" Grid.Row="0" Text="Starting NEXTDEBUT" Foreground="White" FontFamily="Segoe UI Semibold" FontSize="20"/>
                <TextBlock x:Name="ProgressStatus" Grid.Row="2" Text="Initializing..." Foreground="#D5DDED" FontSize="13"/>
                <Grid Grid.Row="4" Height="12">
                    <Border Background="#243049" CornerRadius="6"/>
                    <Border x:Name="ProgressFill" Background="#2F80ED" CornerRadius="6" HorizontalAlignment="Left" Width="24"/>
                </Grid>
                <TextBlock Text="logs\launcher-gui.log" Grid.Row="4" Foreground="#8391AC" FontSize="11" Margin="0,24,0,0"/>
            </Grid>
        </Grid>
    </Border>
</Window>
'@
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $form = [System.Windows.Markup.XamlReader]::Load($reader)
    $form.FindName("ProgressTitle").Text = $titleText
    $titleBar = $form.FindName("ProgressTitleBar")
    $titleBar.Add_MouseLeftButtonDown({
        if ($_.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed) {
            try { $form.DragMove() } catch {}
        }
    })

    $status = $form.FindName("ProgressStatus")
    $bar = $form.FindName("ProgressFill")
    return @{
        Form = $form
        Status = $status
        Bar = $bar
    }
}

function Set-Step($ui, [string]$text, [int]$percent) {
    $ui.Status.Text = $text
    $safePercent = [Math]::Max(0, [Math]::Min(100, $percent))
    $ui.Bar.Width = [Math]::Max(24, [int](460 * ($safePercent / 100.0)))
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke(
        [Action]{},
        [System.Windows.Threading.DispatcherPriority]::Background
    )
}

function Test-HttpReady([string]$url) {
    if (Test-PortOpen 8181 300) {
        return $true
    }
    try {
        $null = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2
        return $true
    } catch {
        if ($_.Exception.Response) {
            try {
                $code = [int]$_.Exception.Response.StatusCode
                return ($code -gt 0)
            } catch {
                return $false
            }
        }
        return $false
    }
}

function Test-PortOpen([int]$port, [int]$timeoutMs = 250) {
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
        if ($client -ne $null) {
            try { $client.Close() } catch {}
        }
    }
}

function Resolve-PythonCommand {
    $candidates = @()
    if (Test-Path $portablePythonPath) { $candidates += "`"$portablePythonPath`"" }
    if (Get-Command py -ErrorAction SilentlyContinue) { $candidates += "py -3" }
    if (Get-Command python -ErrorAction SilentlyContinue) { $candidates += "python" }
    foreach ($candidate in $candidates) {
        $ver = & cmd /c "$candidate --version" 2>&1
        if ($LASTEXITCODE -eq 0 -and $ver -match "Python 3\.") {
            return $candidate
        }
    }
    return $null
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

function Get-PythonScriptsPath([string]$pyCmd) {
    if ([string]::IsNullOrWhiteSpace($pyCmd)) {
        return $null
    }
    try {
        $scriptsPath = (& cmd /c "$pyCmd -c `"import sysconfig; print(sysconfig.get_path('scripts') or '')`"" 2>$null | Select-Object -First 1)
        if (-not [string]::IsNullOrWhiteSpace($scriptsPath)) {
            $scriptsPath = ([string]$scriptsPath).Trim()
            if (Test-Path $scriptsPath) {
                return $scriptsPath
            }
        }
    } catch {
    }
    return $null
}

function Initialize-PythonPath([string]$pyCmd) {
    $scriptsPath = Get-PythonScriptsPath $pyCmd
    if ($scriptsPath) {
        Add-PathPrefix $scriptsPath
        Write-LauncherLog "python scripts path ready: $scriptsPath"
    }
    return $scriptsPath
}

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

function Get-PortableJavaExe {
    $jreRoot = Join-Path $projectRoot "runtime\jre"
    if (-not (Test-Path $jreRoot)) {
        return $null
    }
    if (Test-JdkRootLayout $jreRoot) {
        return (Join-Path $jreRoot "bin\java.exe")
    }
    try {
        foreach ($dir in (Get-ChildItem $jreRoot -Directory -ErrorAction SilentlyContinue)) {
            if ($dir.Name -like "jdk*" -and (Test-JdkRootLayout $dir.FullName)) {
                return (Join-Path $dir.FullName "bin\java.exe")
            }
        }
    } catch {
    }
    return $null
}

function Resolve-JavaCommand {
    $portableJava = Get-PortableJavaExe
    if ($portableJava -and (Test-Path $portableJava)) {
        return "`"$portableJava`""
    }
    if (Get-Command java -ErrorAction SilentlyContinue) { return "java" }
    return $null
}

function Resolve-JavaHomeForGradle {
    $portableJava = Get-PortableJavaExe
    if ($portableJava -and (Test-Path $portableJava)) {
        return (Split-Path (Split-Path $portableJava -Parent) -Parent)
    }
    if (-not [string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
        $javaExe = Join-Path $env:JAVA_HOME "bin\java.exe"
        if (Test-Path $javaExe) {
            return $env:JAVA_HOME
        }
    }
    $java = Get-Command java -ErrorAction SilentlyContinue
    if ($java) {
        try {
            $javaPath = (Resolve-Path $java.Source).Path
            $binDir = Split-Path $javaPath -Parent
            $home = Split-Path $binDir -Parent
            if (Test-JdkRootLayout $home) {
                return $home
            }
        } catch {
        }
    }
    return $null
}

function Ensure-Java21 {
    $java = Get-Command java -ErrorAction SilentlyContinue
    $javaCmd = "java"
    $portableJava = Get-PortableJavaExe
    if ($portableJava -and (Test-Path $portableJava)) {
        $javaCmd = "`"$portableJava`""
    } elseif (-not $java) {
        return $false
    }
    $v = (cmd /c "$javaCmd -version 2>&1" | Select-Object -First 1)
    if (-not $v) { return $false }
    return ([string]$v -match 'version\s+"21(\.|")')
}

function Ensure-RuntimeAvailable {
    $hasPortablePython = Test-Path $portablePythonPath
    $hasPortableJava = $null -ne (Get-PortableJavaExe)
    if ((-not $hasPortablePython -or -not $hasPortableJava) -and (Test-Path $ensureRuntimeScript)) {
        Write-LauncherLog "portable runtime missing: Python=$hasPortablePython Java21=$hasPortableJava, running ensure_runtime.ps1"
        $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ensureRuntimeScript -ProjectRoot $projectRoot 2>&1
        foreach ($line in $out) { Write-LauncherLog ([string]$line) }
    }

    $pyCmd = Resolve-PythonCommand
    $hasPython = $false
    if ($pyCmd) {
        Initialize-PythonPath $pyCmd | Out-Null
        $pyVer = & cmd /c "$pyCmd --version" 2>&1
        $hasPython = ($pyVer -match "Python 3\.")
    }
    $hasJava = Ensure-Java21
    if ($hasPython -and $hasJava) {
        return
    }
    if (-not (Test-Path $ensureRuntimeScript)) {
        if (-not $hasPython) { throw "Python 3 is required." }
        if (-not $hasJava) { throw "Java 21 is required." }
        return
    }
    Write-LauncherLog "runtime check: Python=$hasPython Java21=$hasJava, running ensure_runtime.ps1"
    $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ensureRuntimeScript -ProjectRoot $projectRoot 2>&1
    foreach ($line in $out) { Write-LauncherLog ([string]$line) }
    if ($LASTEXITCODE -ne 0) {
        throw "Runtime setup failed. Check logs\launcher-gui.log."
    }
}

function Ensure-PythonDependencies([string]$pyCmd) {
    $requirements = Join-Path $pyDir "requirements.txt"
    if (-not (Test-Path $requirements)) {
        return
    }
    Initialize-PythonPath $pyCmd | Out-Null
    & cmd /c "$pyCmd -c `"import fastapi, uvicorn, sklearn, pydantic`"" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return
    }
    Write-LauncherLog "installing Python dependencies from python-ml\requirements.txt"
    $out = & cmd /c "$pyCmd -m pip install --disable-pip-version-check --no-warn-script-location -r `"$requirements`"" 2>&1
    foreach ($line in $out) { Write-LauncherLog ([string]$line) }
    if ($LASTEXITCODE -ne 0) {
        throw "Python dependency install failed. Check internet connection and logs\launcher-gui.log."
    }
}

function Repair-GradleJavaHome {
    $props = Join-Path $projectRoot "gradle.properties"
    if (-not (Test-Path $props)) {
        return
    }
    $changed = $false
    $lines = Get-Content -LiteralPath $props -ErrorAction SilentlyContinue
    $newLines = foreach ($line in $lines) {
        if ($line -match '^\s*org\.gradle\.java\.home\s*=\s*(.+)\s*$') {
            $configured = $Matches[1].Trim().Trim('"')
            $javaExe = Join-Path $configured "bin\java.exe"
            if (-not (Test-Path $javaExe)) {
                $changed = $true
                "# disabled by NEXTDEBUT launcher: $line"
                continue
            }
        }
        $line
    }
    if ($changed) {
        [System.IO.File]::WriteAllLines($props, [string[]]$newLines, [System.Text.Encoding]::UTF8)
        Write-LauncherLog "disabled invalid org.gradle.java.home in gradle.properties"
    }
}

function Clear-StaleGradleOutputs {
    $targets = @(
        (Join-Path $projectRoot "build\generated"),
        (Join-Path $projectRoot "build\tmp\compileJava")
    )
    foreach ($target in $targets) {
        if (-not (Test-Path $target)) { continue }
        try {
            & attrib -R "$target\*" /S /D 2>$null | Out-Null
            Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop
            Write-LauncherLog "removed stale Gradle output: $target"
        } catch {
            Write-LauncherLog "could not remove stale Gradle output: $target ($($_.Exception.Message))"
        }
    }
}

function Get-PortPids([int]$port) {
    $rows = netstat -ano -p tcp | Select-String -Pattern (":$port\s")
    $out = @()
    foreach ($row in $rows) {
        $line = ($row.Line -replace '\s+', ' ').Trim()
        $parts = $line.Split(' ')
        if ($parts.Length -lt 5) { continue }
        $procIdRaw = $parts[4]
        $procId = 0
        if ([int]::TryParse($procIdRaw, [ref]$procId) -and $procId -gt 0) {
            if ($out -notcontains $procId) {
                $out += $procId
            }
        }
    }
    return $out
}

function Get-NextDebutCandidatePids {
    $candidate = @()
    foreach ($port in @(8181, 8000)) {
        $candidate += Get-PortPids $port
    }
    try {
        $procRows = Get-CimInstance Win32_Process -ErrorAction Stop
        foreach ($proc in $procRows) {
            $cmd = [string]$proc.CommandLine
            if ([string]::IsNullOrWhiteSpace($cmd)) { continue }
            $cmdLc = $cmd.ToLowerInvariant()
            $isNextDebutPython = $cmdLc.Contains("uvicorn app:app") -or $cmdLc.Contains("python-ml\app.py")
            $isNextDebutSpring = $cmdLc.Contains("nextdebut.jar") -or $cmdLc.Contains("gradlew.bat bootrun") -or $cmdLc.Contains("com.java.pro01application")
            $isLauncherConsole = $cmdLc.Contains("nextdebut_python_console") -or $cmdLc.Contains("nextdebut_spring_console") -or $cmdLc.Contains("run-python-console.cmd") -or $cmdLc.Contains("run-spring-console.cmd")
            if ($isNextDebutPython -or $isNextDebutSpring -or $isLauncherConsole) {
                $pid = 0
                if ([int]::TryParse([string]$proc.ProcessId, [ref]$pid) -and $pid -gt 0) {
                    $candidate += $pid
                }
            }
        }
    } catch {
    }
    return ($candidate | Sort-Object -Unique)
}

function Get-ProcessDescendantPids([int[]]$rootPids) {
    $descendants = @()
    if (-not $rootPids -or $rootPids.Count -eq 0) {
        return $descendants
    }
    try {
        $procRows = Get-CimInstance Win32_Process -ErrorAction Stop
        $childrenByParent = @{}
        foreach ($proc in $procRows) {
            $parentId = 0
            $pid = 0
            if (-not [int]::TryParse([string]$proc.ParentProcessId, [ref]$parentId)) { continue }
            if (-not [int]::TryParse([string]$proc.ProcessId, [ref]$pid)) { continue }
            if (-not $childrenByParent.ContainsKey($parentId)) {
                $childrenByParent[$parentId] = New-Object System.Collections.ArrayList
            }
            [void]$childrenByParent[$parentId].Add($pid)
        }

        $queue = New-Object System.Collections.Queue
        foreach ($pid in ($rootPids | Sort-Object -Unique)) {
            $queue.Enqueue($pid)
        }

        while ($queue.Count -gt 0) {
            $current = [int]$queue.Dequeue()
            if (-not $childrenByParent.ContainsKey($current)) { continue }
            foreach ($childPid in $childrenByParent[$current]) {
                if ($descendants -contains $childPid) { continue }
                $descendants += [int]$childPid
                $queue.Enqueue([int]$childPid)
            }
        }
    } catch {
    }
    return ($descendants | Sort-Object -Unique)
}

function Stop-NextDebutServers {
    $killed = @()
    $targets = Get-NextDebutCandidatePids
    foreach ($pidFile in @($pythonConsolePidFile, $springConsolePidFile)) {
        $savedPid = Read-PidFile $pidFile
        if ($savedPid) {
            $targets += $savedPid
        }
    }
    $allTargets = @($targets + (Get-ProcessDescendantPids $targets) | Sort-Object -Unique)
    foreach ($procId in ($allTargets | Sort-Object -Descending)) {
        try {
            & taskkill /PID $procId /T /F | Out-Null
            $killed += $procId
        } catch {
            try {
                Stop-Process -Id $procId -Force -ErrorAction Stop
                $killed += $procId
            } catch {
            }
        }
    }
    foreach ($pidFile in @($pythonConsolePidFile, $springConsolePidFile)) {
        Clear-PidFile $pidFile
    }
    return ($killed | Sort-Object -Unique)
}

function Ensure-ProjectFiles {
    if (-not (Test-Path (Join-Path $pyDir "app.py"))) { throw "python-ml\app.py not found." }
    $hasJar = Test-Path $appJarPath
    $hasGradle = Test-Path (Join-Path $projectRoot "gradlew.bat")
    if (-not $hasJar -and -not $hasGradle) {
        throw "Missing Spring startup target: nextdebut.jar (or nextdebut.jar) or gradlew.bat"
    }
}

function Resolve-SpringStartCommand {
    if (Test-Path $appJarPath) {
        $javaCmd = Resolve-JavaCommand
        if (-not $javaCmd) {
            throw "Java runtime not found. Put runtime\jre\bin\java.exe or install Java 21."
        }
        return "$javaCmd -jar `"$appJarPath`""
    }
    if (-not (Test-Path (Join-Path $projectRoot "gradlew.bat"))) {
        throw "gradlew.bat not found."
    }
    if (-not (Ensure-Java21)) { throw "Java 21 is required." }
    return "gradlew.bat --no-daemon bootRun"
}

function Get-ServerStatus {
    if ($script:isBooting) {
        return "BOOTING"
    }
    # Keep UI smooth: use a fast TCP probe for periodic status checks.
    if (Test-PortOpen 8181 180) {
        return "ON"
    }
    return "OFF"
}

function Get-StatusColor([string]$status) {
    switch ($status) {
        "ON" { return [System.Drawing.Color]::FromArgb(87, 255, 197) }
        "BOOTING" { return [System.Drawing.Color]::FromArgb(255, 226, 120) }
        default { return [System.Drawing.Color]::FromArgb(255, 118, 150) }
    }
}

function New-LauncherButton([string]$text, [int]$x, [int]$y, [int]$w, [int]$h, [string]$variant = "default") {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Size = New-Object System.Drawing.Size($w, $h)
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 82, 92, 124)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(255, 28, 36, 56)
    $btn.ForeColor = [System.Drawing.Color]::FromArgb(255, 237, 240, 255)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10, [System.Drawing.FontStyle]::Regular)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $hoverBack = [System.Drawing.Color]::FromArgb(255, 40, 50, 74)
    $hoverBorder = [System.Drawing.Color]::FromArgb(255, 130, 148, 188)
    if ($variant -eq "primary") {
        $btn.BackColor = [System.Drawing.Color]::FromArgb(255, 64, 139, 230)
        $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 124, 190, 255)
        $btn.ForeColor = [System.Drawing.Color]::FromArgb(255, 246, 250, 255)
        $hoverBack = [System.Drawing.Color]::FromArgb(255, 82, 158, 246)
        $hoverBorder = [System.Drawing.Color]::FromArgb(255, 160, 211, 255)
    } elseif ($variant -eq "danger") {
        $btn.BackColor = [System.Drawing.Color]::FromArgb(255, 72, 45, 58)
        $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 175, 102, 132)
        $hoverBack = [System.Drawing.Color]::FromArgb(255, 92, 54, 70)
        $hoverBorder = [System.Drawing.Color]::FromArgb(255, 215, 124, 158)
    } elseif ($variant -eq "subtle") {
        $btn.BackColor = [System.Drawing.Color]::FromArgb(255, 30, 35, 56)
        $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 64, 72, 98)
        $hoverBack = [System.Drawing.Color]::FromArgb(255, 42, 48, 76)
        $hoverBorder = [System.Drawing.Color]::FromArgb(255, 108, 124, 168)
    }
    $baseBack = $btn.BackColor
    $baseBorder = $btn.FlatAppearance.BorderColor
    $baseFore = $btn.ForeColor
    $btn.Tag = [PSCustomObject]@{
        BaseBack = $baseBack
        BaseBorder = $baseBorder
        BaseFore = $baseFore
        HoverBack = $hoverBack
        HoverBorder = $hoverBorder
    }
    $btn.Add_MouseEnter({
        try {
            $meta = $this.Tag
            if ($meta -ne $null) {
                $this.BackColor = $meta.HoverBack
                $this.FlatAppearance.BorderColor = $meta.HoverBorder
                $this.ForeColor = [System.Drawing.Color]::White
            }
        } catch {
        }
    })
    $btn.Add_MouseLeave({
        try {
            $meta = $this.Tag
            if ($meta -ne $null) {
                $this.BackColor = $meta.BaseBack
                $this.FlatAppearance.BorderColor = $meta.BaseBorder
                $this.ForeColor = $meta.BaseFore
            }
        } catch {
        }
    })
    return $btn
}

function Start-NextDebutAndOpen([string]$modeName, [string]$targetUrl) {
    $script:isBooting = $true
    $script:serverStatus = "BOOTING"
    $ui = New-ProgressForm("Starting NEXTDEBUT ($modeName)")
    $ui.Form.Show()
    [System.Windows.Forms.Application]::DoEvents()

    try {
        # Fast path: if web is already up, open immediately.
        if (Test-HttpReady $userUrl) {
            Set-Step $ui "Server already running. Opening page..." 100
            Start-Process $targetUrl | Out-Null
            Start-Sleep -Milliseconds 150
            $ui.Form.Close()
            $script:isBooting = $false
            $script:serverStatus = "ON"
            Write-LauncherLog "$modeName mode opened (fast path)"
            return
        }

        Set-Step $ui "Checking files..." 10
        Ensure-ProjectFiles

        Set-Step $ui "Checking runtime..." 24
        Ensure-RuntimeAvailable

        Set-Step $ui "Starting Python ML server..." 48
        if (-not (Test-PortOpen 8000 180)) {
            Set-Step $ui "Checking Python 3..." 36
            $pyCmd = Resolve-PythonCommand
            if (-not $pyCmd) { throw "Python 3 is required." }
            $pyVer = & cmd /c "$pyCmd --version" 2>&1
            if ($pyVer -notmatch "Python 3\.") { throw "Python 3 is required. Current: $pyVer" }
            Set-Step $ui "Installing Python packages if needed..." 42
            Ensure-PythonDependencies $pyCmd
            $pyScriptsPath = Initialize-PythonPath $pyCmd
            $pythonLines = @(
                "title NEXTDEBUT_PYTHON_CONSOLE"
                "cd /d `"$pyDir`""
            )
            if ($pyScriptsPath) {
                $pythonLines += "set `"PATH=$pyScriptsPath;%PATH%`""
            }
            $pythonLines += "echo [NEXTDEBUT] Python ML server starting..."
            $pythonLines += "type nul > `"$pythonLog`""
            $pythonLines += "call $pyCmd -m uvicorn app:app --host 127.0.0.1 --port 8000 >> `"$pythonLog`" 2>&1"
            Write-ConsoleScript $pythonConsoleScript $pythonLines
            $pyConsoleProc = Start-Process -FilePath "cmd.exe" -ArgumentList @("/c", "`"$pythonConsoleScript`"") -PassThru
            Save-PidFile $pythonConsolePidFile $pyConsoleProc
        }

        Set-Step $ui "Starting Spring server..." 62
        if (-not (Test-PortOpen 8181 180)) {
            Set-Step $ui "Preparing Spring runtime..." 54
            Repair-GradleJavaHome
            Clear-StaleGradleOutputs
            $springStartCommand = Resolve-SpringStartCommand
            $springLines = @(
                "title NEXTDEBUT_SPRING_CONSOLE"
                "cd /d `"$projectRoot`""
                "echo [NEXTDEBUT] Spring server starting..."
            )
            $javaHomeForGradle = Resolve-JavaHomeForGradle
            if ($javaHomeForGradle) {
                $springLines += "set `"JAVA_HOME=$javaHomeForGradle`""
                $springLines += "set `"PATH=$javaHomeForGradle\bin;%PATH%`""
            }
            $springLines += "type nul > `"$springLog`""
            $springLines += "call $springStartCommand >> `"$springLog`" 2>&1"
            Write-ConsoleScript $springConsoleScript $springLines
            $springConsoleProc = Start-Process -FilePath "cmd.exe" -ArgumentList @("/c", "`"$springConsoleScript`"") -PassThru
            Save-PidFile $springConsolePidFile $springConsoleProc
        }

        Set-Step $ui "Waiting for service..." 72
        $ready = $false
        for ($i = 0; $i -lt 120; $i++) {
            if (Test-HttpReady $userUrl) {
                $ready = $true
                break
            }
            Start-Sleep -Seconds 1
            $pct = [Math]::Min(95, 72 + [int](($i / 120.0) * 23))
            Set-Step $ui "Waiting for server... ($($i + 1)s)" $pct
        }

        Set-Step $ui "Opening page..." 100
        Start-Process $targetUrl | Out-Null
        Start-Sleep -Milliseconds 250
        $ui.Form.Close()

        if (-not $ready) {
            Show-Info "Server startup is delayed. Browser opened first.`nPlease wait a little and press F5."
        }
        $script:isBooting = $false
        $script:serverStatus = Get-ServerStatus
        Write-LauncherLog "$modeName mode started"
    } catch {
        Write-LauncherLog "launcher error: $($_.Exception.Message)"
        $script:isBooting = $false
        $script:serverStatus = Get-ServerStatus
        try { $ui.Form.Close() } catch {}
        Show-Error ([string]$_.Exception.Message)
    }
}

function Show-MainLauncher {
    function New-WpfBrush([string]$hex) {
        $color = [System.Windows.Media.ColorConverter]::ConvertFromString($hex)
        return New-Object System.Windows.Media.SolidColorBrush($color)
    }

    function Get-WpfStatusBrush([string]$status) {
        switch ($status) {
            "ON" { return (New-WpfBrush "#38DFA2") }
            "BOOTING" { return (New-WpfBrush "#E6C84F") }
            default { return (New-WpfBrush "#FF5F87") }
        }
    }

    function Update-WpfStatus {
        $script:serverStatus = Get-ServerStatus
        $statusValue.Text = $script:serverStatus
        $statusValue.Foreground = Get-WpfStatusBrush $script:serverStatus
        if ($script:serverStatus -eq "ON") {
            $statusDetail.Text = "실행 중 · Python 8000 · Spring 8181"
            $statusDot.Fill = New-WpfBrush "#38DFA2"
        } elseif ($script:serverStatus -eq "BOOTING") {
            $statusDetail.Text = "서버를 시작하는 중입니다."
            $statusDot.Fill = New-WpfBrush "#E6C84F"
        } else {
            $statusDetail.Text = "서버가 꺼져 있습니다."
            $statusDot.Fill = New-WpfBrush "#FF5F87"
        }
    }

    $xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="NEXTDEBUT"
        Width="560" Height="360"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        AllowsTransparency="True"
        ResizeMode="NoResize"
        Background="Transparent"
        FontFamily="Segoe UI">
    <Window.Resources>
        <Style x:Key="ChromeButton" TargetType="{x:Type Button}">
            <Setter Property="Width" Value="34"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#C8D0E4"/>
            <Setter Property="FontSize" Value="15"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Button}">
                        <Border x:Name="buttonChrome" Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="buttonChrome" Property="Background" Value="#26304A"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="LauncherButton" TargetType="{x:Type Button}">
            <Setter Property="Height" Value="52"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontFamily" Value="Segoe UI Semibold"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Button}">
                        <Border x:Name="buttonFrame"
                                Background="{TemplateBinding Background}"
                                CornerRadius="8"
                                SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="buttonFrame" Property="Opacity" Value="0.9"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="buttonFrame" Property="Opacity" Value="0.78"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="buttonFrame" Property="Opacity" Value="0.45"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border Background="#101827" CornerRadius="8" BorderBrush="#26324A" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="44"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <Grid x:Name="TitleBar" Grid.Row="0" Background="#121C2D">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Orientation="Horizontal" Margin="18,0,0,0" VerticalAlignment="Center">
                    <Border Width="18" Height="18" CornerRadius="5" Background="#B858F0" Margin="0,0,9,0">
                        <TextBlock Text="▶" Foreground="White" FontSize="9" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="1,0,0,0"/>
                    </Border>
                    <TextBlock Text="NEXTDEBUT" Foreground="#EAF0FF" FontFamily="Segoe UI Semibold" FontSize="13" VerticalAlignment="Center"/>
                </StackPanel>
                <Button x:Name="BtnMinimize" Grid.Column="1" Style="{StaticResource ChromeButton}" Content="−"/>
                <Button x:Name="BtnClose" Grid.Column="2" Style="{StaticResource ChromeButton}" Content="×" Margin="0,0,8,0"/>
            </Grid>

            <Grid Grid.Row="1" Margin="28,24,28,28">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="26"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0">
                    <TextBlock Text="NEXTDEBUT" Foreground="White" FontFamily="Segoe UI Semibold" FontSize="30"/>
                    <TextBlock Text="프로젝트 서버 런처" Foreground="#90A0BD" FontSize="13" Margin="1,4,0,0"/>
                </StackPanel>

                <Border Grid.Row="2" Background="#172235" CornerRadius="8" Padding="18,16">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Ellipse x:Name="StatusDot" Width="11" Height="11" Fill="#FF5F87" VerticalAlignment="Top" Margin="0,8,14,0"/>
                        <StackPanel Grid.Column="1">
                            <TextBlock Text="현재 상태" Foreground="#8D9AB4" FontFamily="Segoe UI Semibold" FontSize="11"/>
                            <TextBlock x:Name="StatusValue" Text="OFF" Foreground="#FF5F87" FontFamily="Segoe UI Semibold" FontSize="34" Margin="0,1,0,0"/>
                            <TextBlock x:Name="StatusDetail" Text="서버가 꺼져 있습니다." Foreground="#D5DDED" FontSize="13" Margin="1,2,0,0"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <Grid Grid.Row="4">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="14"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="BtnStart" Grid.Column="0" Style="{StaticResource LauncherButton}" Background="#2F80ED" Content="서버 켜기"/>
                    <Button x:Name="BtnStop" Grid.Column="2" Style="{StaticResource LauncherButton}" Background="#3A2631" Content="서버 끄기"/>
                </Grid>
            </Grid>
        </Grid>
    </Border>
</Window>
'@

    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
    $titleBar = $window.FindName("TitleBar")
    $btnMinimize = $window.FindName("BtnMinimize")
    $btnClose = $window.FindName("BtnClose")
    $statusValue = $window.FindName("StatusValue")
    $statusDetail = $window.FindName("StatusDetail")
    $statusDot = $window.FindName("StatusDot")
    $btnStart = $window.FindName("BtnStart")
    $btnStop = $window.FindName("BtnStop")

    Update-WpfStatus

    $titleBar.Add_MouseLeftButtonDown({
        if ($_.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed) {
            try { $window.DragMove() } catch {}
        }
    })
    $btnMinimize.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
    $btnClose.Add_Click({ $window.Close() })

    $statusTimer = New-Object System.Windows.Threading.DispatcherTimer
    $statusTimer.Interval = [TimeSpan]::FromSeconds(2)
    $statusTimer.Add_Tick({ Update-WpfStatus })
    $statusTimer.Start()

    $btnStart.Add_Click({
        $btnStart.IsEnabled = $false
        try {
            Start-NextDebutAndOpen "Manual" $userUrl
        } finally {
            $btnStart.IsEnabled = $true
            Update-WpfStatus
        }
    })

    $btnStop.Add_Click({
        $killed = Stop-NextDebutServers
        if ($killed.Count -gt 0) {
            Write-LauncherLog "servers stopped (pid: $($killed -join ', '))"
            Show-Info "서버를 중지했습니다.`nPID: $($killed -join ', ')"
        } else {
            Show-Info "실행 중인 NEXTDEBUT 서버가 없습니다."
        }
        $script:isBooting = $false
        Update-WpfStatus
    })

    $window.Add_Closing({
        try {
            Stop-NextDebutServers | Out-Null
            Write-LauncherLog "launcher closed - servers stopped"
        } catch {}
    })

    try {
        [void]$window.ShowDialog()
    } finally {
        $statusTimer.Stop()
    }
}

Write-LauncherLog "launcher open"
try {
    Show-MainLauncher
} finally {
    try {
        $launcherMutex.ReleaseMutex() | Out-Null
        $launcherMutex.Dispose()
    } catch {
    }
}
