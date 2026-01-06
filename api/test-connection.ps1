# Database Connection Test Script (PowerShell)
# 
# This script tests the database connection using MySQL command line
# Run with: .\test-connection.ps1

Write-Host "Testing database connection..." -ForegroundColor Cyan
Write-Host ""

# Load environment variables from .env file if it exists
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

# Get database credentials from environment or use defaults
$dbUser = $env:DB_USER
$dbPassword = $env:DB_PASSWORD
$dbName = if ($env:DB_NAME) { $env:DB_NAME } else { "minecraft_church" }
$dbHost = if ($env:DB_HOST) { $env:DB_HOST } else { "localhost" }

if (-not $dbUser) {
    Write-Host "❌ Error: DB_USER not found in .env file" -ForegroundColor Red
    Write-Host "   Please make sure you have completed Step 5 of the setup guide." -ForegroundColor Yellow
    exit 1
}

Write-Host "Database: $dbName" -ForegroundColor Gray
Write-Host "User: $dbUser" -ForegroundColor Gray
Write-Host "Host: $dbHost" -ForegroundColor Gray
Write-Host ""

# Try to find MySQL executable
$mysqlPath = $null
$possiblePaths = @(
    "C:\xampp\mysql\bin\mysql.exe",
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe",
    "C:\Program Files\MySQL\MySQL Server 8.1\bin\mysql.exe",
    "mysql.exe"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $mysqlPath = $path
        break
    }
    # Also try if it's in PATH
    $found = Get-Command $path -ErrorAction SilentlyContinue
    if ($found) {
        $mysqlPath = $path
        break
    }
}

if (-not $mysqlPath) {
    Write-Host "❌ Error: MySQL executable not found" -ForegroundColor Red
    Write-Host "   Please make sure MySQL is installed and in your PATH" -ForegroundColor Yellow
    Write-Host "   Or update this script with the correct path to mysql.exe" -ForegroundColor Yellow
    exit 1
}

Write-Host "Using MySQL: $mysqlPath" -ForegroundColor Gray
Write-Host ""

# Test connection
try {
    if ($dbPassword) {
        $passwordArg = "-p$dbPassword"
        $result = & $mysqlPath -h $dbHost -u $dbUser $passwordArg $dbName -e "SELECT 1 as test;" 2>&1
    } else {
        $result = & $mysqlPath -h $dbHost -u $dbUser $dbName -e "SELECT 1 as test;" 2>&1
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Database connection successful!" -ForegroundColor Green
        Write-Host ""
        
        # Check tables
        if ($dbPassword) {
            $tables = & $mysqlPath -h $dbHost -u $dbUser $passwordArg $dbName -e "SHOW TABLES;" 2>&1
        } else {
            $tables = & $mysqlPath -h $dbHost -u $dbUser $dbName -e "SHOW TABLES;" 2>&1
        }
        
        if ($LASTEXITCODE -eq 0) {
            $tableCount = ($tables | Select-String -Pattern "Tables_in" | Measure-Object).Count
            Write-Host "✅ Found $tableCount table(s) in database" -ForegroundColor Green
            Write-Host ""
            Write-Host "✅ All tests passed! Your database is ready to use." -ForegroundColor Green
        }
    } else {
        throw "Connection failed"
    }
} catch {
    Write-Host "❌ Database connection failed!" -ForegroundColor Red
    Write-Host "Error output:" -ForegroundColor Yellow
    Write-Host $result -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "   - Check if MySQL server is running" -ForegroundColor Gray
    Write-Host "   - Verify username and password in .env file" -ForegroundColor Gray
    Write-Host "   - Make sure database '$dbName' exists" -ForegroundColor Gray
    exit 1
}
