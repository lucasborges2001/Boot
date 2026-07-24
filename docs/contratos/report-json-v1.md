# Contrato `report.json` v1

## Estado

Contrato legacy soportado para lectura y compatibilidad.

Boot emite `schema_version=2` desde la extensión de telemetría host, pero `BootReportNormalizer`, `BootReportReader` y `BootHistoryService` continúan aceptando snapshots v1.

## Campos mínimos esperados

```json
{
  "module": "boot",
  "schema_version": 1,
  "generated_at": "2026-07-07T00:00:00Z",
  "status": {},
  "server": {},
  "metrics": {},
  "updates": {},
  "services": {},
  "telegram": {},
  "artifacts": {}
}
```

## Reglas de compatibilidad

- `module` debe ser `boot`.
- `generated_at` es variable y debe normalizarse en comparaciones.
- Telegram no es fuente de verdad.
- la ausencia de `cpu`, `memory`, `filesystems`, `disk_io` y `network_interfaces` se normaliza como objetos o listas vacías;
- la API no expone rutas absolutas aunque el snapshot legacy las contenga;
- `ip_wan` se normaliza a `null`;
- los tests no requieren sensores reales ni systemd funcional.

## Fixture

```txt
var/sample-reports/v1/report.json
```

## Migración

Los consumidores deben leer primero los campos v1 existentes y tratar los campos v2 como extensiones opcionales. No deben exigir que todo histórico tenga `schema_version=2`.

El contrato vigente de escritura está documentado en [`report-json-v2.md`](report-json-v2.md).
