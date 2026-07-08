# Contrato con Base

## Objetivo

Definir qué toma `Boot` desde `Base` y qué conserva como lógica propia.

## Resolución de Base

Orden efectivo esperado:

1. `BASE_DIR` si apunta a una instalación con `lib/shell/env.sh`.
2. `../Base` junto a `Boot`, layout típico de `Pruebas/submodules`.
3. `/opt/base` en producción.

En PHP, `back/bootstrap.php` intenta cargar `Base/back/bootstrap.php` y `base_bootstrap_load_core()`. Si el bootstrap no existe, intenta cargar clases Base concretas necesarias para smoke/local.

## Helpers shell Base

Boot usa desde Base:

```bash
source "$BASE_DIR/lib/shell/env.sh"
source "$BASE_DIR/lib/shell/log.sh"
source "$BASE_DIR/lib/shell/json.sh"
source "$BASE_DIR/lib/shell/lock.sh"
source "$BASE_DIR/lib/shell/time.sh"
source "$BASE_DIR/lib/shell/telegram.sh"
```

## Clases PHP Base esperadas

- `MetricSeverity`
- `MetricStatus`
- `MetricSnapshot`
- `MetricSnapshotReader`
- `MetricSnapshotNormalizer`
- `JsonMetricSnapshotRepository`
- `TelegramHtml`
- `TelegramResponse`
- `TelegramResponseParser`

## Responsabilidad propia de Boot

Boot conserva lógica de dominio servidor:

- hostname;
- kernel;
- uptime;
- IP LAN;
- load promedio;
- RAM;
- disco raíz;
- temperatura cuando existe;
- updates pendientes;
- reboot requerido;
- servicios systemd fallidos;
- formatter específico del reporte Boot;
- lectura de historial Boot.

## Límites

No mover a Boot:

- parseo genérico de `.env`;
- logging genérico;
- lock genérico;
- helpers JSON genéricos;
- cliente Telegram genérico;
- contrato común de métricas.

## Criterio de cierre

El contrato queda sólido cuando `bash scripts/dev/smoke.sh` pasa con `BASE_DIR=../Base` y también con `BASE_DIR=/opt/base` en una instalación real.
