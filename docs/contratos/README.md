# Contratos

Contratos técnicos vigentes de `Boot`.

| Documento | Propósito |
|---|---|
| [`base-observabilidad.md`](base-observabilidad.md) | Dependencia con `Base` y límites de duplicación. |
| [`report-json-v1.md`](report-json-v1.md) | Shape operativo de `report.json`. |
| [`api-json-readonly.md`](api-json-readonly.md) | Contrato HTTP/JSON de API pública y SuperAdmin. |
| [`packaging.md`](packaging.md) | Contrato de paquetes server/web. |

## Reglas generales

- `Boot` depende de `Base`; no debe copiar helpers genéricos.
- La fuente de verdad local es `report.json`, no Telegram.
- API y SuperAdmin son read-only.
- Telegram es salida opcional.
- Packaging debe poder generarse sin secretos reales.
