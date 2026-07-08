# Contrato `report.json` v1

## Identidad

```json
{
  "module": "boot",
  "schema_version": 1
}
```

## Ruta canónica

```txt
/var/lib/boot-report/reports/latest/report.json
```

El directorio puede cambiar con `BOOT_REPORTS_DIR`.

## Estructura principal

| Campo | Tipo | Descripción |
|---|---|---|
| `module` | string | Debe ser `boot`. |
| `schema_version` | int | Versión de schema. Actual: `1`. |
| `generated_at` | string | Timestamp ISO-like con timezone. |
| `server` | object | Hostname, kernel, uptime e IPs. |
| `status` | object | Estado general, severidad y resumen. |
| `metrics` | object | Load, RAM, disco y temperatura. |
| `updates` | object | Updates totales, security y reboot requerido. |
| `services` | object | Servicios fallidos. |
| `telegram` | object | Resultado de envío opcional. |
| `artifacts` | object | Rutas a artefactos persistidos. |

## Severidad

Valores observados/esperados:

- `ok`
- `info`
- `warning`
- `critical`
- `unknown`

## Campos `server`

```json
{
  "hostname": "server-01",
  "kernel": "6.x",
  "uptime_seconds": 123456,
  "ip_lan": "192.168.1.10",
  "ip_wan": null
}
```

## Campos `metrics`

```json
{
  "cpu_load_1m": 0.21,
  "cpu_load_5m": 0.18,
  "cpu_load_15m": 0.16,
  "ram_used_percent": 47.5,
  "disk_root_used_percent": 62.1,
  "temperature_c": 48
}
```

## Campos `telegram`

```json
{
  "enabled": true,
  "last_send_ok": true,
  "message_id": 123,
  "description": null
}
```

`telegram` no debe ser usado como fuente única de auditoría. La fuente de verdad es el JSON persistido.

## Compatibilidad API

`BootReportNormalizer::normalizeForApi()` expone además `base_snapshot`, derivado de `MetricSnapshot`. Ese campo permite integrar Boot con contratos comunes de observabilidad de Base.

## Criterio de aceptación

```bash
BOOT_REPORTS_DIR=/tmp/boot-report/reports BOOT_SEND_TELEGRAM=false \
  bin/boot-report --no-telegram --print | python3 -m json.tool

test -f /tmp/boot-report/reports/latest/report.json
test -f /tmp/boot-report/reports/latest/summary.txt
```
