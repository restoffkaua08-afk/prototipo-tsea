
# Estrutura Final do Projeto TSEA V-Twin

## Objetivo

Este repositório foi organizado para apresentação do protótipo TSEA V-Twin. A estrutura foi reduzida para manter somente os componentes necessários ao funcionamento e explicação do sistema.

## Pastas principais

### `gateway_fisico/backend`

Backend FastAPI do projeto.

Arquivos importantes:

* `app/main.py`: aplicação principal e rotas centrais.
* `app/real_bridge.py`: ponte de parâmetros reais/simulados.
* `app/charts_bridge.py`: geração dos dados dos gráficos.
* `app/google_sheets_bridge.py`: integração com Google Planilhas.
* `requirements.txt`: dependências Python.

### `ihm_operador/frontend`

Interface da IHM do operador.

Arquivos importantes:

* `src/main.tsx`: aplicação da IHM.
* `package.json`: dependências e scripts.
* `vite.config.ts`: configuração Vite e proxy para o Gateway.

### `sistema_gerente/frontend`

Sistema web gerencial.

Arquivos importantes:

* `src/pages/TraceabilityChartsPanel.tsx`: tela de indicadores e gráficos.
* `package.json`: dependências e scripts.
* `vite.config.ts`: configuração Vite e proxy para o Gateway.

### `scripts`

Scripts auxiliares para abrir e validar o sistema.

### `docs`

Documentação do projeto, relatórios e materiais de apresentação.

## Arquivos removidos/ignorados

Foram removidos ou ignorados:

* `node_modules`
* ambientes virtuais Python
* builds gerados
* caches
* backups antigos
* arquivos `.bak`
* logs
* temporários
* arquivos sensíveis `.local.json`

## Ordem sugerida para apresentação

1. `gateway_fisico/backend`: cérebro do sistema.
2. `ihm_operador/frontend`: operação no chão de fábrica.
3. `sistema_gerente/frontend`: análise gerencial e gráficos.
4. `scripts`: abertura e validação.
5. `docs`: documentação final.
   '@ | Set-Content -Encoding UTF8 "$DestinoRaiz\ESTRUTURA_FINAL_TSEA.md"

Write-Host "Criando script de abertura..." -ForegroundColor Cyan

@'
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null

$Repo = Split-Path -Parent $PSScriptRoot
$Backend = "$Repo\gateway_fisico\backend"
$Ihm = "$Repo\ihm_operador\frontend"
$Gerente = "$Repo\sistema_gerente\frontend"
$PythonVenv = "$Backend.venv_gateway\Scripts\python.exe"

function Stop-Port {
param([int]$Port)

```
Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique |
    ForEach-Object {
        Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
    }
```

}

Stop-Port 8020
Stop-Port 5178
Stop-Port 5173

cd $Backend

if (!(Test-Path $PythonVenv)) {
python -m venv ".venv_gateway"
}

& $PythonVenv -m pip install -r requirements.txt

Start-Process powershell.exe -ArgumentList @(
"-NoExit",
"-NoProfile",
"-ExecutionPolicy", "Bypass",
"-Command",
"cd `"$Backend`"; `"$PythonVenv`" -m uvicorn app.main:app --host 127.0.0.1 --port 8020 --reload"
)

Start-Sleep -Seconds 8

cd $Ihm
npm install

Start-Process powershell.exe -ArgumentList @(
"-NoExit",
"-NoProfile",
"-ExecutionPolicy", "Bypass",
"-Command",
"cd `"$Ihm`"; npm run dev -- --host 127.0.0.1 --port 5178"
)

Start-Sleep -Seconds 5

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

Invoke-WebRequest "[http://127.0.0.1:8020/api/state](http://127.0.0.1:8020/api/state)" -UseBasicParsing | Out-Null
Invoke-WebRequest "[http://127.0.0.1:5178](http://127.0.0.1:5178)" -UseBasicParsing | Out-Null
Invoke-WebRequest "[http://127.0.0.1:5173](http://127.0.0.1:5173)" -UseBasicParsing | Out-Null

Start-Process "[http://127.0.0.1:8020/docs](http://127.0.0.1:8020/docs)"
Start-Process "[http://127.0.0.1:5178](http://127.0.0.1:5178)"
Start-Process "[http://127.0.0.1:5173](http://127.0.0.1:5173)"

Write-Host "Sistema TSEA aberto." -ForegroundColor Green
Write-Host "Gateway/API: [http://127.0.0.1:8020/docs](http://127.0.0.1:8020/docs)" -ForegroundColor Green
Write-Host "IHM: [http://127.0.0.1:5178](http://127.0.0.1:5178)" -ForegroundColor Green
Write-Host "Gerente: [http://127.0.0.1:5173](http://127.0.0.1:5173)" -ForegroundColor Green
