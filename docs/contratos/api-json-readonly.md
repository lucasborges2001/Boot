# Contrato API JSON read-only

## Endpoints públicos

```txt
public_html/api/health.php
public_html/api/latest.php
public_html/api/history.php
public_html/api/summary.php
public_html/api/details.php?section=cpu
public_html/api/details.php?section=memory
public_html/api/details.php?section=filesystems
public_html/api/details.php?section=network
public_html/api/details.php?section=disk_io
```

## Endpoints SuperAdmin

```txt
public_html/superadmin/api/latest.php
public_html/superadmin/api/history.php
public_html/superadmin/api/probe.php
public_html/superadmin/api/summary.php
public_html/superadmin/api/details.php?section=cpu|memory|filesystems|network|disk_io
```

## Método permitido

Solo `GET`.

Métodos no permitidos responden:

- HTTP `405`;
- header `Allow: GET`;
- JSON estable con `ok=false`, `module=boot`, `code=METHOD_NOT_ALLOWED`.

## Headers

Las respuestas web incluyen:

```txt
Content-Type: application/json; charset=utf-8
Cache-Control: no-store, max-age=0
Pragma: no-cache
X-Content-Type-Options: nosniff
```

## Shape de éxito

```json
{
  "ok": true,
  "module": "boot",
  "code": "OK",
  "data": {}
}
```

## Shape de error

```json
{
  "ok": false,
  "module": "boot",
  "code": "NO_SNAPSHOT",
  "error": {
    "message": "No Boot snapshot available"
  }
}
```

Los errores internos usan un mensaje genérico. No se exponen excepciones, rutas absolutas ni secretos.

## Ausencia de snapshot

Los fixtures no sustituyen un snapshot runtime por defecto. `BOOT_ALLOW_SAMPLE_REPORTS=false` es el comportamiento normal.

- `health` responde `snapshot_available=false`;
- `latest` y `details` responden `NO_SNAPSHOT`;
- `history` devuelve una lista vacía;
- `summary` devuelve `available=false` y tendencias no disponibles.

Los tests pueden apuntar explícitamente `BOOT_REPORTS_DIR` a `var/sample-reports`.

## Resumen y tendencias

`summary.php` incluye:

- estado y servidor;
- métricas operativas actuales;
- updates y servicios fallidos;
- tendencias calculadas sobre historial Boot.

Una tendencia se publica solo cuando existen al menos dos valores numéricos válidos para la métrica. Contiene:

```json
{
  "samples": 3,
  "first": 40.0,
  "latest": 60.0,
  "minimum": 40.0,
  "maximum": 60.0,
  "average": 50.0,
  "delta": 20.0,
  "direction": "rising"
}
```

Las direcciones posibles son `rising`, `falling` y `stable`.

## Contrato de detalle

`details.php` requiere una sección allowlisted. Una sección inválida responde `INVALID_SECTION` con HTTP `400`.

Las respuestas de historial usan `snapshot_id` y nunca `path`. La lectura histórica ignora symlinks, archivos corruptos y directorios fuera del árbol administrado.

Los artefactos API se expresan como rutas lógicas relativas:

```json
{
  "report_json": "latest/report.json",
  "summary_txt": "latest/summary.txt"
}
```

## Regla read-only

La capa API y SuperAdmin no debe contener:

```txt
shell_exec
exec(
system(
passthru
proc_open
popen
<form
method="post"
```

La recolección pertenece exclusivamente al CLI `bin/boot-report`; PHP web solo lee snapshots persistidos.
