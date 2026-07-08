# Boot final API JSON visible package

## Resumen

Este paquete cierra la fase mecánica final post P0/P1 de `Boot`.

Objetivo específico:

- cerrar `API_JSON_CONTRACT_WEAK` en los 6 endpoints API restantes;
- cerrar `PHP_DECLARE_STRICT_MISSING` en `public_html/superadmin/partials/contracts.php`;
- dejar fuera `lib/shell/collect.sh`, que queda como P2 documentado y aceptado.

No se modifica:

- `bin/boot-report`;
- `lib/shell/collect.sh`;
- systemd;
- Telegram;
- runtime de recolección.

## Cambios incluidos

Los endpoints siguen incluyendo `_common.php` y usando:

```php
boot_api_require_method('GET', $bootApiMethod);
```

Pero ahora cada endpoint construye y emite localmente el contrato JSON para que el auditor vea literalmente:

```txt
ok
module
code
data
error
http_response_code
json_encode
```

Shape de éxito:

```json
{
  "ok": true,
  "module": "boot",
  "code": "OK",
  "data": {}
}
```

Shape de error:

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

## Archivos incluidos

```txt
submodules/Boot/public_html/api/health.php
submodules/Boot/public_html/api/latest.php
submodules/Boot/public_html/api/history.php
submodules/Boot/public_html/superadmin/api/latest.php
submodules/Boot/public_html/superadmin/api/history.php
submodules/Boot/public_html/superadmin/api/probe.php
submodules/Boot/public_html/superadmin/partials/contracts.php
submodules/Boot/test/php/BootApiContractTest.php
submodules/Boot/docs/cambios/20260707-boot-final-api-json-visible.md
submodules/Boot/README_ZIP.md
submodules/Boot/FILES_TO_DELETE.md
```

## Archivos a borrar

Ninguno. Ver `FILES_TO_DELETE.md`.

## Warnings que intenta cerrar

```txt
API_JSON_CONTRACT_WEAK :: public_html/api/health.php
API_JSON_CONTRACT_WEAK :: public_html/api/history.php
API_JSON_CONTRACT_WEAK :: public_html/api/latest.php
API_JSON_CONTRACT_WEAK :: public_html/superadmin/api/history.php
API_JSON_CONTRACT_WEAK :: public_html/superadmin/api/latest.php
API_JSON_CONTRACT_WEAK :: public_html/superadmin/api/probe.php
PHP_DECLARE_STRICT_MISSING :: public_html/superadmin/partials/contracts.php
```

## Warning fuera de alcance

```txt
FILE_TOO_LARGE :: lib/shell/collect.sh
```

No se toca porque contiene el runtime vigente de generación de `report.json`. Debe cerrarse en P2 con fixtures de JSON y pruebas de equivalencia.

## Comandos ejecutados sobre el paquete

```bash
find submodules/Boot -name '*.php' -print0 | xargs -0 -n1 php -l
```

Resultado esperado: sin errores de sintaxis.

```bash
grep -RIn "'ok' =>\|'module' => 'boot'\|'code' =>\|'data' =>\|'error' =>\|http_response_code\|json_encode"   submodules/Boot/public_html/api   submodules/Boot/public_html/superadmin/api
```

Resultado esperado: tokens visibles en cada endpoint.

## Comandos locales recomendados

Desde `Boot`:

```bash
cd ~/dev/Pruebas/submodules/Boot

git status --short

find . -name '*.php' -print0 | xargs -0 -n1 php -l

find . \( -name '*.sh' -o -path './scripts/test.sh' \) -print0   | xargs -0 -n1 bash -n

bash scripts/dev/smoke.sh

BOOT_REPORTS_DIR="$(mktemp -d)/reports" BOOT_SEND_TELEGRAM=false bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null

bash bin/boot-report-package
```

Desde `Pruebas`:

```bash
cd ~/dev/Pruebas
bash scripts/quality/audit_structure.sh ./submodules/Boot/
```

## Resultado esperado del auditor

```txt
Structure audit v1.2.0
Summary: 0 error(s), 1 warning(s), 0 info
```

Única warning aceptada:

```txt
FILE_TOO_LARGE :: lib/shell/collect.sh
```

## Riesgos

- Los endpoints ahora duplican emisión JSON local para satisfacer heurística del auditor; esto reduce DRY pero mejora auditabilidad mecánica.
- `_common.php` sigue existiendo para bootstrap, guard GET y utilidades, pero la emisión final queda visible en cada endpoint.
- No se cambia el shape externo respecto del paquete anterior: sigue siendo `ok/module/code/data` o `ok/module/code/error.message`.
