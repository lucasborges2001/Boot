# 2026-07-07 — Boot P0/P1 hardening

## Resumen

Se agrega cierre P0/P1 para `Boot` sin convertirlo en runtime obligatorio del host.

## Cambios

- Documentación estructural requerida por perfil `module`.
- Refactor compatible de `lib/render.sh` y `lib/system.sh` en agregadores chicos.
- API read-only con `_common.php`, método `GET` y JSON estable.
- Bootstrap PHP separado en resolver explícito de Base.
- Headers mecánicos PHP/JS.
- Packaging tolerante a rutas opcionales inexistentes.
- Test productivo manual separado del smoke seguro.

## Validaciones esperadas

```bash
bash scripts/dev/smoke.sh
BOOT_REPORTS_DIR="$(mktemp -d)/reports" BOOT_SEND_TELEGRAM=false bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null
bash bin/boot-report-package
bash scripts/quality/audit_structure.sh ./submodules/Boot/
```

## Fuera de alcance

- Refactor de `lib/shell/collect.sh`.
- Migración completa de SuperAdmin a componentes Base UI.
- Prueba Telegram real.
