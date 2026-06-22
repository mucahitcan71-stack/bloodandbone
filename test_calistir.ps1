# Blood and Bone — headless crash-test araci (oyun mantigina dokunmaz).
# Calistirma: .\test_calistir.ps1           (varsayilan 30 sn)
#             .\test_calistir.ps1 60        (60 sn)
# Execution policy engellerse: powershell -ExecutionPolicy Bypass -File .\test_calistir.ps1

param(
    [int]$Saniye = 30
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $ProjectRoot "test_log.txt"
$ErrFile = Join-Path $ProjectRoot "test_log_stderr.txt"

Write-Host ""
Write-Host "UYARI: Bu arac yalnizca crash/hata kontrolu yapar." -ForegroundColor Yellow
Write-Host "       Gorsel dogrulama (UI, buton konumu, tasma vb.) YAPMAZ." -ForegroundColor Yellow
Write-Host ""

function Find-GodotExecutable {
    if ($env:GODOT_PATH -and (Test-Path $env:GODOT_PATH)) {
        return (Resolve-Path $env:GODOT_PATH).Path
    }

    $cmdNames = @("godot", "Godot", "godot4", "Godot_v4.6-stable_win64.exe")
    foreach ($name in $cmdNames) {
        $found = Get-Command $name -ErrorAction SilentlyContinue
        if ($found) { return $found.Source }
    }

    $searchRoots = @(
        "$env:LOCALAPPDATA\Programs\Godot",
        "$env:ProgramFiles\Godot",
        "$env:ProgramFiles\Godot Engine",
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop"
    )

    foreach ($root in $searchRoots) {
        if (-not (Test-Path $root)) { continue }
        $match = Get-ChildItem -Path $root -Filter "Godot*.exe" -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($match) { return $match.FullName }
    }

    return $null
}

$godot = Find-GodotExecutable
if (-not $godot) {
    Write-Host "HATA: Godot bulunamadi. PATH'e ekleyin veya GODOT_PATH ortam degiskenini ayarlayin." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path (Join-Path $ProjectRoot "project.godot"))) {
    Write-Host "HATA: project.godot bulunamadi: $ProjectRoot" -ForegroundColor Red
    exit 1
}

"" | Set-Content -Path $LogFile -Encoding UTF8
if (Test-Path $ErrFile) { Remove-Item $ErrFile -Force }

$godotArgs = @(
    "--headless",
    "--path", $ProjectRoot
)

Write-Host "Godot: $godot"
Write-Host "Sure:  $Saniye saniye (headless crash test)"
Write-Host "Log:   $LogFile"
Write-Host ""

$proc = Start-Process -FilePath $godot -ArgumentList $godotArgs `
    -RedirectStandardOutput $LogFile `
    -RedirectStandardError $ErrFile `
    -PassThru -NoNewWindow

$timeoutMs = [math]::Max(1, $Saniye) * 1000
$exited = $proc.WaitForExit($timeoutMs)

if (-not $exited) {
    try { $proc.Kill() } catch { }
    $proc.WaitForExit(5000) | Out-Null
    Add-Content -Path $LogFile -Value "`n--- Script: $Saniye saniye doldu, Godot sonlandirildi ---" -Encoding UTF8
}

if (Test-Path $ErrFile) {
    $stderr = Get-Content -Path $ErrFile -Raw -ErrorAction SilentlyContinue
    if ($stderr) {
        Add-Content -Path $LogFile -Value "`n--- STDERR ---`n$stderr" -Encoding UTF8
    }
    Remove-Item $ErrFile -Force -ErrorAction SilentlyContinue
}

$logText = Get-Content -Path $LogFile -Raw -ErrorAction SilentlyContinue
if (-not $logText) { $logText = "" }

$errorPatterns = @(
    "ERROR",
    "SCRIPT ERROR",
    "Invalid",
    "Nonexistent function"
)

$foundErrors = @()
foreach ($pattern in $errorPatterns) {
    if ($logText -match [regex]::Escape($pattern)) {
        $foundErrors += $pattern
    }
}

if ($foundErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "TEST BAŞARISIZ - hata bulundu, test_log.txt dosyasına bak" -ForegroundColor Red
    Write-Host "Eslesen anahtar kelimeler: $($foundErrors -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "TEST BAŞARILI - $Saniye saniye crash olmadan çalıştı" -ForegroundColor Green
exit 0
