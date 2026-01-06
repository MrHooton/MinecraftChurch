# Complete XAMPP MySQL Permission Fix Script
# Run this PowerShell script AS ADMINISTRATOR

Write-Host "=== XAMPP MySQL Permission Fix ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit
}

$mysqlDataPath = "C:\xampp\mysql\data"
$mysqlPath = "C:\xampp\mysql"

# Check if path exists
if (-not (Test-Path $mysqlDataPath)) {
    Write-Host "ERROR: MySQL data path not found: $mysqlDataPath" -ForegroundColor Red
    pause
    exit
}

Write-Host "Step 1: Stopping MySQL processes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -like "*mysql*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "Step 2: Removing read-only attributes..." -ForegroundColor Yellow
Get-ChildItem -Path $mysqlDataPath -Recurse | ForEach-Object {
    if ($_.Attributes -match "ReadOnly") {
        $_.Attributes = $_.Attributes -bxor [System.IO.FileAttributes]::ReadOnly
    }
}

Write-Host "Step 3: Granting full permissions..." -ForegroundColor Yellow
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Grant permissions to current user
icacls $mysqlDataPath /grant "${currentUser}:(OI)(CI)F" /T | Out-Null

# Grant permissions to SYSTEM (MySQL service runs as SYSTEM)
icacls $mysqlDataPath /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T | Out-Null

# Grant permissions to Administrators
icacls $mysqlDataPath /grant "BUILTIN\Administrators:(OI)(CI)F" /T | Out-Null

# Specific files that need permissions
$criticalFiles = @("ibdata1", "ib_logfile0", "ib_logfile1", "aria_log_control", "aria_log.00000001")
foreach ($file in $criticalFiles) {
    $filePath = Join-Path $mysqlDataPath $file
    if (Test-Path $filePath) {
        Write-Host "  Fixing permissions for: $file" -ForegroundColor Gray
        icacls $filePath /grant "${currentUser}:(OI)(CI)F" | Out-Null
        icacls $filePath /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" | Out-Null
    }
}

Write-Host "Step 4: Taking ownership..." -ForegroundColor Yellow
takeown /F $mysqlDataPath /R /D Y | Out-Null

Write-Host ""
Write-Host "=== Fix Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Open XAMPP Control Panel" -ForegroundColor White
Write-Host "2. Try starting MySQL again" -ForegroundColor White
Write-Host ""
Write-Host "If it still doesn't work, try:" -ForegroundColor Yellow
Write-Host "- Run XAMPP Control Panel as Administrator" -ForegroundColor White
Write-Host "- Or restart your computer" -ForegroundColor White
Write-Host ""
pause
