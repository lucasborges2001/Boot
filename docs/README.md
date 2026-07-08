# Documentación de Boot

`Boot` es un submódulo de tooling opcional para bootstrap y observabilidad de servidor. Su objetivo es generar snapshots read-only del host, persistirlos como artefactos locales, exponerlos por API/UI y enviar opcionalmente un resumen por Telegram.

## Estado actual auditado

Última validación reportada desde el checkout real:

```txt
Structure audit v1.2.0
Root: /home/Lucas/dev/Pruebas/submodules/Boot
Profile: module
Summary: 0 error(s), 1 warning(s), 0 info
```

Única advertencia viva:

```txt
FILE_TOO_LARGE :: lib/shell/collect.sh
```

Validaciones funcionales reportadas como OK:

```bash
find . -name '*.php' -print0 | xargs -0 -n1 php -l
find . \( -name '*.sh' -o -path './scripts/test.sh' \) -print0 | xargs -0 -n1 bash -n
bash scripts/dev/smoke.sh
BOOT_REPORTS_DIR="$(mktemp -d)/reports" BOOT_SEND_TELEGRAM=false bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null
bash bin/boot-report-package
```

## Estado por área

| Área | Estado | Nota |
|---|---|---|
| Estructura documental requerida | Cerrada | Existen `estructura-modulo.md`, `contrato-host-modulo.md` y checklist modular. |
| Runtime CLI | Operable | `bin/boot-report` genera JSON válido sin Telegram real. |
| Dependencia `Base` | Operable | Resolución movida a frontera dedicada. |
| API pública | Operable read-only | Endpoints GET con contrato JSON visible. |
| SuperAdmin API | Operable read-only | Endpoints GET con contrato JSON visible. |
| Packaging | Operable | `boot-server.tar.gz` y `boot-web.tar.gz` se generan. |
| Smokes | Operables | `scripts/dev/smoke.sh` pasa completo. |
| Auditor estructural | Casi limpio | Queda solo `lib/shell/collect.sh` grande. |
| Producción real | Pendiente | Falta validación controlada con systemd/Telegram real o Telegram deshabilitado explícitamente. |

## Carpetas

| Carpeta | Uso |
|---|---|
| [`operacion/`](operacion/) | Arquitectura, instalación, API/UI, testing y operación diaria. |
| [`contratos/`](contratos/) | Contratos de Base, JSON, API read-only y packaging. |
| [`auditorias/`](auditorias/) | Auditorías de estado y cierre P0/P1. |
| [`cambios/`](cambios/) | Cambios documentales y técnicos ya cerrados. |
| [`pendientes/`](pendientes/) | Backlog vivo priorizado. |
| [`checklists/`](checklists/) | Checklist requerido por auditor estructural. |

## Lectura recomendada

1. [`estructura-modulo.md`](estructura-modulo.md)
2. [`contrato-host-modulo.md`](contrato-host-modulo.md)
3. [`contratos/api-json-readonly.md`](contratos/api-json-readonly.md)
4. [`operacion/testing.md`](operacion/testing.md)
5. [`auditorias/20260707-1900-boot-cierre-p0-p1.md`](auditorias/20260707-1900-boot-cierre-p0-p1.md)
6. [`pendientes/README.md`](pendientes/README.md)

## Regla de operación

Boot puede observar, persistir y publicar estado read-only del servidor. No debe convertirse en panel de ejecución remota, orquestador de cambios del host ni dependencia runtime obligatoria de `Pruebas`.
