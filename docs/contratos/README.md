# Contratos

Contratos técnicos vigentes de `Boot`.

| Documento | Propósito |
|---|---|
| [`base-observabilidad.md`](base-observabilidad.md) | Dependencia con `Base` y límites de duplicación. |
| [`report-json-v1.md`](report-json-v1.md) | Schema operativo de `report.json`. |
| [`packaging.md`](packaging.md) | Contrato de paquetes server/web y brecha detectada. |

## Reglas

- `Boot` depende de `Base`; no debe copiar helpers genéricos.
- El schema principal es `boot/v1` representado por `module=boot` y `schema_version=1`.
- API y SuperAdmin son read-only.
- Telegram es salida opcional, no fuente de verdad.
- La fuente de verdad local es `BOOT_REPORTS_DIR/latest/report.json`.
