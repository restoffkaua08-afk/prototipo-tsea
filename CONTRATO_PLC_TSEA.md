# Contrato PLC / ESP32 - TSEA V-Twin

Este documento define como o PLC/ESP32 conversa com o Gateway Python.

## Fluxo recomendado

1. IHM ou Gerente inicia a operacao.
2. Gateway calcula as saidas desejadas.
3. PLC/ESP32 consulta as saidas desejadas.
4. PLC/ESP32 aplica as saidas em bancada segura.
5. PLC/ESP32 envia leituras reais/simuladas de volta.
6. IHM e Gerente exibem diagnostico fisico.

## Endpoints

### Consultar saidas desejadas

GET http://127.0.0.1:8020/api/hardware/desired-outputs

Campos principais:

- pump_b1: bomba primaria ou rele/LED de bancada
- pump_b2: lampada simulando bomba Roots
- oil_valve: valvula/LED de oleo
- alarm_green: farol verde
- alarm_yellow: farol amarelo
- alarm_red: farol vermelho
- emergency_stop: parada/bloqueio

### Enviar leituras do PLC/ESP32

POST http://127.0.0.1:8020/api/hardware/ingest

Exemplo:

{
  "status": "EM_CICLO",
  "stage": "VACUO_INICIAL",
  "elapsed_seconds": 12,
  "pressure_machine_mbar": 850,
  "pumps": {
    "b1": true,
    "b2": false,
    "oil": false
  },
  "oil": {
    "injected_l": 0,
    "remaining_l": 80,
    "flow_l_min": 0
  },
  "hardware": {
    "sensor_online": true,
    "plc_online": true,
    "emergency": false
  },
  "event": "Pacote recebido do PLC"
}

### Confirmar comando aplicado

POST http://127.0.0.1:8020/api/hardware/command-ack

Exemplo:

{
  "command_id": "CMD-0001",
  "applied": true,
  "message": "Saidas aplicadas em bancada",
  "outputs": {
    "pump_b1": true,
    "pump_b2": false,
    "oil_valve": false
  }
}

## Modos

POST http://127.0.0.1:8020/api/hardware/mode

Exemplo:

{ "mode": "BANCADA_SEGURA" }

Modos aceitos:

- SIMULADO
- BANCADA_SEGURA
- FISICO_HTTP
- MODBUS_TCP

Para apresentacao, use BANCADA_SEGURA com LED, lampada ou rele sem carga perigosa.