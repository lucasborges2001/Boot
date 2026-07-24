# Documentación de Boot

`Boot` es un submódulo opcional de telemetría host. Genera snapshots read-only, mantiene historial local controlado, expone API/UI y puede enviar un resumen por Telegram usando capacidades de `Base`.

## Estado de implementación

La rama `main` contiene la extensión de telemetría schema v2:

- colectores separados para sistema, CPU, memoria, filesystems y red;
- CPU mediante dos muestras de `/proc/stat`;
- memoria, swap y PSI;
- filesystems e inodos allowlisted;
- I/O de disco opcional por dispositivos allowlisted;
- contadores y tasas de red con detección de reboot/counter reset;
- persistencia atómica y snapshots append-only;
- retención por días y máximo de archivos;
- lectura compatible de snapshots v1/v2;
- API y SuperAdmin read-only con `Cache-Control: no-store`;
- sanitización de rutas internas y errores;
- fixtures y tests deterministas.

## Estado de validación

No debe darse por cerrada la validación solo por la presencia del código. Ejecutar desde un checkout con `Base` disponible:

```bash
find . -name '*.php' -print0 | xargs -0 -n1 php -l
find . \( -name '*.sh' -o -path './scripts/test.sh' \) -print0 | xargs -0 -n1 bash -n
BASE_DIR=../Base bash scripts/dev/smoke.sh
BOOT_REPORTS_DIR="$(mktemp -d)/reports" BOOT_SEND_TELEGRAM=false bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null
bash bin/boot-report-package
```

Desde `Pruebas`:

```bash
bash scripts/quality/audit_structure.sh ./submodules/Boot/
```

Objetivo estructural tras dividir `lib/shell/collect.sh`: `0 error(s), 0 warning(s)`; requiere comprobación real.

## Estado por área

| Área | Estado | Nota |
|---|---|---|
| Arquitectura y contratos | Implementado | Schema v2 aditivo con lectura v1/v2. |
| Colectores host | Implementado | Linux procfs/sysfs con fallbacks y `null` explícito. |
| Persistencia histórica | Implementado | Latest atómico, append-only y pruning confinado. |
| API pública | Implementado | Health, latest, history, summary y details. |
| SuperAdmin | Implementado | Métricas, filesystems y red read-only. |
| Tests deterministas | Implementado | CPU, memoria, red, reset/reboot, retención y API. |
| Smoke de checkout | No verificado en esta revisión | Requiere entorno con Base. |
| Producción real | Pendiente | No se validó systemd, Telegram real ni hardware/sensores reales. |
| Integración host `Pruebas` | Pendiente | Falta actualizar gitlink y ejecutar smokes del host. |

## Carpetas

| Carpeta | Uso |
|---|---|
| [`operacion/`](operacion/) | Arquitectura, instalación, API/UI, testing y operación diaria. |
| [`contratos/`](contratos/) | Contratos de Base, schema v1/v2, API read-only y packaging. |
| [`auditorias/`](auditorias/) | Auditorías históricas. |
| [`cambios/`](cambios/) | Cambios técnicos cerrados. |
| [`pendientes/`](pendientes/) | Backlog restante de Boot. |
| [`checklists/`](checklists/) | Checklist modular. |

## Lectura recomendada

1. [`estructura-modulo.md`](estructura-modulo.md)
2. [`contrato-host-modulo.md`](contrato-host-modulo.md)
3. [`contratos/report-json-v2.md`](contratos/report-json-v2.md)
4. [`contratos/report-json-v1.md`](contratos/report-json-v1.md)
5. [`contratos/api-json-readonly.md`](contratos/api-json-readonly.md)
6. [`operacion/testing.md`](operacion/testing.md)

## Regla de operación

Boot puede observar, persistir y publicar estado read-only del servidor. No debe convertirse en panel de ejecución remota, orquestador de cambios del host ni dependencia runtime obligatoria de `Pruebas`.
