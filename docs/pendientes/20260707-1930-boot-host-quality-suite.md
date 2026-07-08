# P1 — Agregar suite host opcional desde Pruebas

## Objetivo

Validar Boot desde `Pruebas` sin convertirlo en dependencia obligatoria.

## Motivo

Boot es tooling opcional, pero puede degradarse sin que el host lo note.

## Ruta sugerida

Crear en `Pruebas`:

```txt
scripts/quality/boot_tooling_smoke.sh
```

Debe ejecutar:

```bash
cd submodules/Boot
bash scripts/dev/smoke.sh
BOOT_REPORTS_DIR="$(mktemp -d)/reports" BOOT_SEND_TELEGRAM=false bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null
bash bin/boot-report-package
```

## Regla

Debe ser manual/opcional. No bloquear deploy de aplicación por defecto.

## Criterio de cierre

- Suite existe.
- Documenta que Boot es tooling opcional.
- Puede ejecutarse localmente desde raíz de `Pruebas`.
