# Contrato API JSON read-only

## Endpoints

```txt
public_html/api/health.php
public_html/api/latest.php
public_html/api/history.php
public_html/superadmin/api/latest.php
public_html/superadmin/api/history.php
public_html/superadmin/api/probe.php
```

## Método permitido

Solo `GET`.

Métodos no permitidos deben responder:

- HTTP `405`;
- header `Allow: GET`;
- JSON estable con `ok=false`, `module=boot`, `code=METHOD_NOT_ALLOWED`.

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

## Regla read-only

La capa API no debe contener:

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

Si se agrega una operación futura, debe ser otro módulo/endpoint con autorización explícita. Boot API actual es consulta.
