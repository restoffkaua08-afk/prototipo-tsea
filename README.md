# Protótipo TSEA V-Twin

Sistema de demonstração do projeto TSEA V-Twin para controle, monitoramento, rastreabilidade e geração de gráficos do processo de vácuo em tanques/reguladores.

## Estrutura principal

```txt
prototipo-tsea/
├── gateway_fisico/
│   └── backend/
│       ├── app/
│       ├── data/
│       └── requirements.txt
├── ihm_operador/
│   └── frontend/
│       ├── src/
│       ├── package.json
│       └── vite.config.ts
├── sistema_gerente/
│   └── frontend/
│       ├── src/
│       ├── package.json
│       └── vite.config.ts
├── docs/
├── scripts/
├── README.md
└── ESTRUTURA_FINAL_TSEA.md
````

## Portas

* Gateway/API: [http://127.0.0.1:8020](http://127.0.0.1:8020)
* IHM do operador: [http://127.0.0.1:5178](http://127.0.0.1:5178)
* Sistema gerente: [http://127.0.0.1:5173](http://127.0.0.1:5173)

## Como abrir

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\abrir_tsea_completo.ps1
```

## Componentes

### Gateway/API

Backend FastAPI responsável por estado da operação, receitas, mangueiras, comandos, rastreabilidade, gráficos e integração com Google Planilhas.

### IHM do Operador

Interface para o operador preparar e iniciar a operação.

### Sistema Gerente

Interface gerencial para acompanhar operação, cadastros, indicadores, gráficos e relatórios.

## Segurança

Arquivos `.local.json`, tokens OAuth e segredos Google não devem ser commitados.
