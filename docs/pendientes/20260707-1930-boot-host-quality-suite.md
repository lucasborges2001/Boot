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

## Auditoría estática — 2026-11-02

**Estado: abierto, integración externa no verificada.** En Boot existe `scripts/dev/smoke.sh`, que ejecuta lint PHP/Bash/Python, tests shell/PHP y `bin/boot-report-test`. Esto cubre la capacidad local de prueba, **no** la suite opcional propuesta en el host `Pruebas`.

**Owner:** el wrapper `scripts/quality/boot_tooling_smoke.sh` corresponde a `lucasborges2001/Pruebas`; no copiarlo a Boot. Antes de implementarlo, verificar `AGENTS.md`, ubicación real del submódulo, gitlink y scripts de calidad existentes en Pruebas.

**PASS:** wrapper opcional en el host que ejecuta el SHA exacto del gitlink, produce evidencia y no bloquea despliegues por defecto. **No verificado:** repositorio Pruebas, ejecución de TestKit, suite host y resultados de CI.
