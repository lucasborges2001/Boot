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

## Contrato de detalle

`details.php` requiere una sección allowlisted. Una sección inválida responde `INVALID_SECTION` con HTTP `400`.

Las respuestas de historial usan `snapshot_id` y nunca `path`.

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
