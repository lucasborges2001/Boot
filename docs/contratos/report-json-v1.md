# Contrato `report.json` v1

## Archivo principal

```txt
reports/latest/report.json
```

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

## Reglas

- `module` debe ser `boot`.
- `schema_version` debe mantenerse en `1` hasta que exista migración explícita.
- `generated_at` es variable y debe normalizarse en comparaciones.
- Telegram no debe ser fuente de verdad.
- Los tests no deben requerir sensores reales ni systemd funcional.

## Riesgo principal

`lib/shell/collect.sh` genera este contrato. Por eso su refactor debe comparar el JSON antes/después y no solo pasar `bash -n`.
