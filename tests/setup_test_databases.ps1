# Setup test databases for backend comparison testing
# PowerShell version for Windows

# Database configuration
$SOURCE_DB = "allourphotos_asus"
$TEST_DB_PYTHON = "allourphotos_test_python"
$TEST_DB_NODE = "allourphotos_test_node"

# MySQL credentials (customize these)
$DB_HOST = "localhost"
$DB_USER = "photos"
$DB_PASS = "photos00"

# MySQL client path (adjust if needed)
$MYSQL_PATH = "mysql"
$MYSQLDUMP_PATH = "mysqldump"

Write-Host "========================================" -ForegroundColor Green
Write-Host "Test Database Setup Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Source database: $SOURCE_DB"
Write-Host "Target databases:"
Write-Host "  - $TEST_DB_PYTHON (for Python backend)"
Write-Host "  - $TEST_DB_NODE (for Node backend)"
Write-Host ""

# Confirm before proceeding
$response = Read-Host "This will DROP and recreate the test databases. Continue? (y/N)"
if ($response -ne "y" -and $response -ne "Y") {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit
}

# Check if MySQL is accessible
Write-Host "`nChecking MySQL connection..." -ForegroundColor Yellow
try {
    $null = & $MYSQL_PATH -h $DB_HOST -u $DB_USER -p"$DB_PASS" -e "SELECT 1" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "MySQL connection failed"
    }
} catch {
    Write-Host "ERROR: Cannot connect to MySQL. Check credentials and MySQL path." -ForegroundColor Red
    Write-Host "MySQL path: $MYSQL_PATH" -ForegroundColor Yellow
    exit 1
}

# Check if source database exists
Write-Host "Checking source database..." -ForegroundColor Yellow
$checkDb = & $MYSQL_PATH -h $DB_HOST -u $DB_USER -p"$DB_PASS" -e "USE $SOURCE_DB" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Source database '$SOURCE_DB' does not exist!" -ForegroundColor Red
    exit 1
}

# Get record counts from source
Write-Host "`nSource database statistics:" -ForegroundColor Green
$query = @"
SELECT 'aopusers' as table_name, COUNT(*) as count FROM aopusers
UNION ALL SELECT 'aopsessions', COUNT(*) FROM aopsessions
UNION ALL SELECT 'aopalbums', COUNT(*) FROM aopalbums
UNION ALL SELECT 'aopsnaps', COUNT(*) FROM aopsnaps
UNION ALL SELECT 'aopalbum_items', COUNT(*) FROM aopalbum_items;
"@
& $MYSQL_PATH -h $DB_HOST -u $DB_USER -p"$DB_PASS" $SOURCE_DB -e $query

Write-Host ""
Read-Host "Press Enter to continue with database copy"

# Create temporary dump file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$DUMP_FILE = "$env:TEMP\${SOURCE_DB}_dump_${timestamp}.sql"

Write-Host "`nStep 1: Dumping source database to $DUMP_FILE..." -ForegroundColor Yellow
& $MYSQLDUMP_PATH -h $DB_HOST -u $DB_USER -p"$DB_PASS" `
    --single-transaction `
    --routines `
    --triggers `
    --events `
    $SOURCE_DB > $DUMP_FILE

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Database dump failed!" -ForegroundColor Red
    exit 1
}

$dumpSize = (Get-Item $DUMP_FILE).Length / 1MB
Write-Host "✓ Dump complete ($([math]::Round($dumpSize, 2)) MB)" -ForegroundColor Green

# Function to create and populate a test database
function Create-TestDatabase {
    param($DbName)

    Write-Host "`nStep 2: Creating test database '$DbName'..." -ForegroundColor Yellow

    # Drop if exists and create new
    $createQuery = @"
DROP DATABASE IF EXISTS $DbName;
CREATE DATABASE $DbName CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
"@
    & $MYSQL_PATH -h $DB_HOST -u $DB_USER -p"$DB_PASS" -e $createQuery

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to create database '$DbName'" -ForegroundColor Red
        return $false
    }

    Write-Host "✓ Database created" -ForegroundColor Green

    Write-Host "Step 3: Importing data into '$DbName'..." -ForegroundColor Yellow
    Get-Content $DUMP_FILE | & $MYSQL_PATH -h $DB_HOST -u $DB_USER -p"$DB_PASS" $DbName

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to import data into '$DbName'" -ForegroundColor Red
        return $false
    }

    Write-Host "✓ Data imported" -ForegroundColor Green

    # Verify record counts
    Write-Host "Verifying record counts in '$DbName':" -ForegroundColor Yellow
    $verifyQuery = @"
SELECT 'aopusers' as table_name, COUNT(*) as count FROM aopusers
UNION ALL SELECT 'aopsessions', COUNT(*) FROM aopsessions
UNION ALL SELECT 'aopalbums', COUNT(*) FROM aopalbums
UNION ALL SELECT 'aopsnaps', COUNT(*) FROM aopsnaps
UNION ALL SELECT 'aopalbum_items', COUNT(*) FROM aopalbum_items;
"@
    & $MYSQL_PATH -h $DB_HOST -u $DB_USER -p"$DB_PASS" $DbName -e $verifyQuery

    return $true
}

# Create both test databases
$success1 = Create-TestDatabase $TEST_DB_PYTHON
if (-not $success1) {
    Write-Host "`nERROR: Failed to create Python test database" -ForegroundColor Red
    Remove-Item $DUMP_FILE -ErrorAction SilentlyContinue
    exit 1
}

Write-Host ""
$success2 = Create-TestDatabase $TEST_DB_NODE
if (-not $success2) {
    Write-Host "`nERROR: Failed to create Node test database" -ForegroundColor Red
    Remove-Item $DUMP_FILE -ErrorAction SilentlyContinue
    exit 1
}

# Clean up dump file
Write-Host "`nCleaning up temporary dump file..." -ForegroundColor Yellow
Remove-Item $DUMP_FILE
Write-Host "✓ Cleanup complete" -ForegroundColor Green

# Final summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Test databases created:"
Write-Host "  ✓ $TEST_DB_PYTHON"
Write-Host "  ✓ $TEST_DB_NODE"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Update pyserver/config.json to use '$TEST_DB_PYTHON'"
Write-Host "  2. Update backend/.env to use '$TEST_DB_NODE'"
Write-Host "  3. Ensure both backends point to the same photos directory"
Write-Host "  4. Start running comparison tests"
Write-Host ""
Write-Host "Note: These test databases are independent copies." -ForegroundColor Yellow
Write-Host "Changes to one will NOT affect the other or the source database." -ForegroundColor Yellow
