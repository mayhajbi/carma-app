# dev.ps1 — starts the local server and Expo in parallel

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$serverPath = Join-Path $root "carma-server-main\local-server"

Write-Host "Starting local server at $serverPath ..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$serverPath'; node server.js"

Write-Host "Starting Expo..." -ForegroundColor Cyan
Set-Location $root
npx expo start
