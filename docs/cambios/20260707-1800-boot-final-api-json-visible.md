# Cambio — Boot API JSON visible final

## Resumen

Los endpoints API construyen y emiten JSON con tokens literales visibles para el auditor.

## Archivos cubiertos

```txt
public_html/api/health.php
public_html/api/latest.php
public_html/api/history.php
public_html/superadmin/api/latest.php
public_html/superadmin/api/history.php
public_html/superadmin/api/probe.php
public_html/superadmin/partials/contracts.php
test/php/BootApiContractTest.php
```

## Contrato visible

Cada endpoint expone de forma directa:

```txt
'ok'
'module'
'code'
'data'
'error'
http_response_code
json_encode
```

## Resultado

El auditor estructural reportado quedó en:

```txt
0 error(s), 1 warning(s), 0 info
```
