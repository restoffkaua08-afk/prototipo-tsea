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

if (!(Test-Path $Backend)) { throw "Backend não encontrado: $Backend" }
if (!(Test-Path $Ihm)) { throw "IHM não encontrada: $Ihm" }
if (!(Test-Path $Gerente)) { throw "Sistema gerente não encontrado: $Gerente" }
if (!(Test-Path $PythonVenv)) { throw "Ambiente virtual não encontrado: $PythonVenv" }

Write-Host "Parando portas antigas..." -ForegroundColor Cyan
Stop-Port 8020
Stop-Port 5178
Stop-Port 5173

Write-Host "Abrindo Gateway/API na porta 8020..." -ForegroundColor Cyan

Start-Process powershell.exe -ArgumentList @(
    "-NoExit",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Command",
    "cd `"$Backend`"; `"$PythonVenv`" -m uvicorn app.main:app --host 127.0.0.1 --port 8020 --reload"
)

Start-Sleep -Seconds 10

Write-Host "Testando Gateway/API..." -ForegroundColor Cyan
Invoke-WebRequest "http://127.0.0.1:8020/api/state" -UseBasicParsing | Out-Null

Write-Host "Abrindo IHM na porta 5178..." -ForegroundColor Cyan
cd $Ihm
npm install

Start-Process powershell.exe -ArgumentList @(
    "-NoExit",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Command",
    "cd `"$Ihm`"; npm run dev -- --host 127.0.0.1 --port 5178"
)

Start-Sleep -Seconds 8

Write-Host "Testando IHM..." -ForegroundColor Cyan
Invoke-WebRequest "http://127.0.0.1:5178" -UseBasicParsing | Out-Null

Write-Host "Abrindo Sistema Gerente na porta 5173..." -ForegroundColor Cyan
cd $Gerente
npm install

Start-Process powershell.exe -ArgumentList @(
    "-NoExit",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Command",
    "cd `"$Gerente`"; npm run dev -- --host 127.0.0.1 --port 5173"
)

Start-Sleep -Seconds 8

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
