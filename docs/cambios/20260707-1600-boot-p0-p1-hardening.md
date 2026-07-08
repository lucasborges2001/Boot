# Cambio — Boot P0/P1 hardening

## Resumen

Cierre de los errores principales del auditor estructural.

## Cierres

- `DOC_REQUIRED_MISSING` para `docs/checklists/auditoria-modularidad-modulo.md`.
- `DOC_REQUIRED_MISSING` para `docs/contrato-host-modulo.md`.
- `DOC_REQUIRED_MISSING` para `docs/estructura-modulo.md`.
- `FILE_CRITICAL_SIZE :: lib/render.sh`.
- `FILE_CRITICAL_SIZE :: lib/system.sh`.
- Packaging con manifests y smoke.
- Separación de test productivo en `scripts/server/test-production.sh`.

## Validación reportada

- `php -l`: OK.
- `bash -n`: OK.
- `scripts/dev/smoke.sh`: OK.
- `bin/boot-report-package`: OK.
