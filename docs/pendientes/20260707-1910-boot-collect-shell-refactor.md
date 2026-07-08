# P2 — Refactor controlado de `lib/shell/collect.sh`

## Motivo

Única warning restante del auditor:

```txt
FILE_TOO_LARGE :: lib/shell/collect.sh
```

No se debe tocar sin fixtures porque genera el contrato `report.json`.

## Plan sugerido

1. Crear fixtures para `/proc/meminfo`, `/proc/loadavg`, `df`, `apt`, `systemctl`, sensores y red.
2. Separar por dominio:

```txt
lib/shell/collect/basic.sh
lib/shell/collect/resources.sh
lib/shell/collect/temperature.sh
lib/shell/collect/updates.sh
lib/shell/collect/services.sh
lib/shell/collect/network.sh
lib/shell/collect/report.sh
lib/shell/collect.sh
```

3. Mantener `lib/shell/collect.sh` como agregador compatible.
4. Comparar JSON antes/después normalizando `generated_at` y host/IP variables.

## Criterio de cierre

- Auditor queda en `0 error(s), 0 warning(s)` o deja de marcar tamaño.
- `scripts/dev/smoke.sh` pasa.
- `bin/boot-report --no-telegram --print` mantiene shape y tipos.
