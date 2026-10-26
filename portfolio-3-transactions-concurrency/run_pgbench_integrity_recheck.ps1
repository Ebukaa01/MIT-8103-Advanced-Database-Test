# =====================================================================
# EquityPay Financial Services Ltd. - PostgreSQL 18
# Portfolio 3: pgbench Integrity Recheck Automation Script
# =====================================================================

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Running Post-pgbench Financial Integrity Recheck Suite... " -ForegroundColor Cyan
Write-Host " Target Database: EquityPay_db | Engine: PostgreSQL 18 " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$psqlPath = if (Get-Command psql -ErrorAction SilentlyContinue) { "psql" } else { "C:\Program Files\PostgreSQL\18\bin\psql.exe" }
$sqlFile = "portfolio-3-transactions-concurrency/07_integrity_check.sql"
$outputFile = "portfolio-3-transactions-concurrency/output/pgbench_integrity_recheck.txt"

# Execute audit query against EquityPay_db
& $psqlPath -U postgres -d EquityPay_db -f $sqlFile | Tee-Object $outputFile

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Integrity audit completed successfully!" -ForegroundColor Green
Write-Host " Results exported to: $outputFile" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
