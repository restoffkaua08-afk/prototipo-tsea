$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null

$Repo = Split-Path -Parent $PSScriptRoot
$Backend = Join-Path $Repo "gateway_fisico\backend"
$Ihm = Join-Path $Repo "ihm_operador\frontend"
$Gerente = Join-Path $Repo "sistema_gerente\frontend"
$PythonVenv = Join-Path $Backend ".venv_gateway\Scripts\python.exe"

function Stop-Port {
    param([int]$Port)

    Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess -Unique |
        ForEach-Object {
            Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
        }
}

if (!(Test-Path $Backend)) {
    throw "Backend não encontrado: $Backend"
}

if (!(Test-Path $Ihm)) {
    throw "IHM não encontrada: $Ihm"
}

if (!(Test-Path $Gerente)) {
    throw "Sistema gerente não encontrado: $Gerente"
}

Write-Host "Parando portas antigas..." -ForegroundColor Cyan
Stop-Port 8020
Stop-Port 5178
Stop-Port 5173

Write-Host "Preparando Gateway/API..." -ForegroundColor Cyan
cd $Backend

if (!(Test-Path $PythonVenv)) {
    python -m venv ".venv_gateway"
}

& $PythonVenv -m pip install --upgrade pip
& $PythonVenv -m pip install -r requirements.txt

& $PythonVenv -m py_compile ".\app\main.py"

if (Test-Path ".\app\real_bridge.py") {
    & $PythonVenv -m py_compile ".\app\real_bridge.py"
}

if (Test-Path ".\app\charts_bridge.py") {
    & $PythonVenv -m py_compile ".\app\charts_bridge.py"
}

if (Test-Path ".\app\google_sheets_bridge.py") {
    & $PythonVenv -m py_compile ".\app\google_sheets_bridge.py"
}

Write-Host "Abrindo Gateway/API na porta 8020..." -ForegroundColor Cyan

Start-Process powershell.exe -ArgumentList @(
    "-NoExit",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Command",
    "cd `"$Backend`"; `"$PythonVenv`" -m uvicorn app.main:app --host 127.0.0.1 --port 8020 --reload"
)

Start-Sleep -Seconds 8

Write-Host "Testando Gateway/API..." -ForegroundColor Cyan
Invoke-WebRequest "http://127.0.0.1:8020/api/state" -UseBasicParsing | Out-Null

Write-Host "Preparando IHM..." -ForegroundColor Cyan
cd $Ihm
npm install

Write-Host "Abrindo IHM na porta 5178..." -ForegroundColor Cyan

Start-Process powershell.exe -ArgumentList @(
    "-NoExit",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Command",
    "cd `"$Ihm`"; npm run dev -- --host 127.0.0.1 --port 5178"
)

Start-Sleep -Seconds 7

Write-Host "Testando IHM..." -ForegroundColor Cyan
Invoke-WebRequest "http://127.0.0.1:5178" -UseBasicParsing | Out-Null

Write-Host "Preparando Sistema Gerente..." -ForegroundColor Cyan
cd $Gerente
npm install

Write-Host "Abrindo Sistema Gerente na porta 5173..." -ForegroundColor Cyan

Start-Process powershell.exe -ArgumentList @(
    "-NoExit",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Command",
    "cd `"$Gerente`"; npm run dev -- --host 127.0.0.1 --port 5173"
)

Start-Sleep -Seconds 7

Write-Host "Testando Sistema Gerente..." -ForegroundColor Cyan
Invoke-WebRequest "http://127.0.0.1:5173" -UseBasicParsing | Out-Null

Start-Process "http://127.0.0.1:8020/docs"
Start-Process "http://127.0.0.1:5178"
Start-Process "http://127.0.0.1:5173"

Write-Host ""
Write-Host "Sistema TSEA aberto." -ForegroundColor Green
Write-Host "Gateway/API: http://127.0.0.1:8020/docs" -ForegroundColor Green
Write-Host "IHM: http://127.0.0.1:5178" -ForegroundColor Green
Write-Host "Gerente: http://127.0.0.1:5173" -ForegroundColor Green
