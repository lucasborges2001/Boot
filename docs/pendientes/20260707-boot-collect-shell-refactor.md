# Pendiente P2 — Refactor controlado de `lib/shell/collect.sh`

## Motivo

El auditor estructural sigue marcando:

```txt
FILE_TOO_LARGE :: lib/shell/collect.sh
```

No se refactoriza en la fase post P0/P1 porque `lib/shell/collect.sh` es parte del runtime vigente usado por `bin/boot-report` para generar el contrato `report.json`.

## Funciones principales involucradas

- `boot_collect_hostname`
- `boot_collect_kernel`
- `boot_collect_uptime`
- `boot_collect_load`
- `boot_collect_memory`
- `boot_collect_disk`
- `boot_collect_temperature`
- `boot_collect_updates`
- `boot_collect_reboot_required`
- `boot_collect_failed_services`
- `boot_collect_network`
- `boot_collect_report_json`
- `boot_report_set_telegram_result`

## Riesgo

Extraer sin fixtures puede cambiar silenciosamente:

- nombres de claves JSON;
- tipos numéricos/booleanos;
- fallback de temperatura;
- detección de updates por distro;
- listado de servicios fallidos;
- semántica de `BOOT_SEND_TELEGRAM=false`.

## Plan sugerido

1. Crear fixtures shell para salidas de `df`, `/proc/meminfo`, `/proc/loadavg`, `apt list`, `systemctl` y sensores.
2. Separar en módulos:

```txt
lib/shell/collect/basic.sh
lib/shell/collect/resources.sh
lib/shell/collect/updates.sh
lib/shell/collect/services.sh
lib/shell/collect/network.sh
lib/shell/collect/report.sh
lib/shell/collect.sh
```

3. Mantener `lib/shell/collect.sh` como agregador compatible.
4. Comparar `bin/boot-report --no-telegram --print` antes/después con normalización de `generated_at`.
5. Ejecutar `bash scripts/dev/smoke.sh` y packaging.

## Criterio de cierre

El auditor debe dejar de marcar `FILE_TOO_LARGE` y el JSON generado debe conservar shape y tipos funcionales.
