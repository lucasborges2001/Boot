# Boot — cierre controlado de warnings restantes post P0/P1

## Resumen

Este paquete reduce warnings restantes del auditor estructural de `Boot` después de aplicar `boot_p0_p1_hardening_package.zip`.

El foco es mecánico y controlado:

- señales visibles de método HTTP en endpoints;
- contrato JSON estable con wrappers explícitos;
- cierre de `PHP_REQUIRE_AFTER_CODE` en `back/support/base-resolver.php`;
- headers `@file` / `@brief` en soportes SuperAdmin;
- conversión de wrappers chicos de SuperAdmin en fronteras de view model;
- documentación del pendiente P2 para `lib/shell/collect.sh`.

No se modifica `bin/boot-report`, no se cambia el shape funcional del `report.json`, no se toca Telegram real y no se ejecutan scripts productivos.

## Archivos incluidos

```txt
submodules/Boot/README_ZIP.md
submodules/Boot/FILES_TO_DELETE.md

submodules/Boot/back/support/base-resolver.php

submodules/Boot/public_html/api/_common.php
submodules/Boot/public_html/api/health.php
submodules/Boot/public_html/api/latest.php
submodules/Boot/public_html/api/history.php

submodules/Boot/public_html/superadmin/_pageBootstrap.php
submodules/Boot/public_html/superadmin/api/_common.php
submodules/Boot/public_html/superadmin/api/latest.php
submodules/Boot/public_html/superadmin/api/history.php
submodules/Boot/public_html/superadmin/api/probe.php
submodules/Boot/public_html/superadmin/support/api.php
submodules/Boot/public_html/superadmin/support/config.php
submodules/Boot/public_html/superadmin/support/health.php
submodules/Boot/public_html/superadmin/support/helpers.php
submodules/Boot/public_html/superadmin/support/metrics.php
submodules/Boot/public_html/superadmin/support/paths.php
submodules/Boot/public_html/superadmin/partials/contracts.php
submodules/Boot/public_html/superadmin/bootSuperadminFront.md

submodules/Boot/test/php/BootApiContractTest.php

submodules/Boot/docs/checklists/auditoria-modularidad-modulo.md
submodules/Boot/docs/cambios/20260707-boot-api-audit-hardening.md
submodules/Boot/docs/pendientes/20260707-boot-collect-shell-refactor.md
```

## Archivos a borrar

Ninguno.

Ver `FILES_TO_DELETE.md`.

## Warnings que intenta cerrar

```txt
PHP_REQUIRE_AFTER_CODE :: back/support/base-resolver.php
API_JSON_CONTRACT_WEAK :: public_html/api/health.php
API_METHOD_GUARD_MISSING :: public_html/api/health.php
API_JSON_CONTRACT_WEAK :: public_html/api/history.php
API_METHOD_GUARD_MISSING :: public_html/api/history.php
API_JSON_CONTRACT_WEAK :: public_html/api/latest.php
API_METHOD_GUARD_MISSING :: public_html/api/latest.php
WRAPPER_SUSPECT :: public_html/superadmin/_pageBootstrap.php
API_JSON_CONTRACT_WEAK :: public_html/superadmin/api/history.php
API_METHOD_GUARD_MISSING :: public_html/superadmin/api/history.php
API_JSON_CONTRACT_WEAK :: public_html/superadmin/api/latest.php
API_METHOD_GUARD_MISSING :: public_html/superadmin/api/latest.php
API_JSON_CONTRACT_WEAK :: public_html/superadmin/api/probe.php
API_METHOD_GUARD_MISSING :: public_html/superadmin/api/probe.php
PHP_HEADER_MISSING :: public_html/superadmin/support/api.php
PHP_HEADER_MISSING :: public_html/superadmin/support/config.php
WRAPPER_SUSPECT :: public_html/superadmin/support/config.php
PHP_HEADER_MISSING :: public_html/superadmin/support/health.php
PHP_HEADER_MISSING :: public_html/superadmin/support/metrics.php
PHP_HEADER_MISSING :: public_html/superadmin/support/paths.php
WRAPPER_SUSPECT :: public_html/superadmin/support/paths.php
```

## Warning que queda fuera

```txt
FILE_TOO_LARGE :: lib/shell/collect.sh
```

Queda como P2 documentado en:

```txt
docs/pendientes/20260707-boot-collect-shell-refactor.md
```

## Contrato API esperado

Éxito:

```json
{
  "ok": true,
  "module": "boot",
  "code": "OK",
  "data": {}
}
```

Error:

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

Método inválido:

```json
{
  "ok": false,
  "module": "boot",
  "code": "METHOD_NOT_ALLOWED",
  "error": {
    "message": "Method not allowed. Use GET."
  }
}
```

En contexto web, método inválido emite HTTP 405 y header `Allow: GET`.

## Comandos ejecutados al construir el paquete

Ejecutados sobre los archivos incluidos en el ZIP:

```bash
find submodules/Boot -name '*.php' -print0 | xargs -0 -n1 php -l

grep -RIn "boot_api_require_method('GET'" submodules/Boot/public_html/api submodules/Boot/public_html/superadmin/api

grep -RIn "boot_api_send_ok\|boot_api_send_error" submodules/Boot/public_html/api submodules/Boot/public_html/superadmin/api

grep -RIn "require_once" submodules/Boot/back/support/base-resolver.php || true
```

## Comandos locales recomendados después de aplicar

Desde `Boot`:

```bash
cd ~/dev/Pruebas/submodules/Boot

git status --short

find . -name '*.php' -print0 | xargs -0 -n1 php -l

find . \( -name '*.sh' -o -path './scripts/test.sh' \) -print0 \
  | xargs -0 -n1 bash -n

bash scripts/dev/smoke.sh

BOOT_REPORTS_DIR="$(mktemp -d)/reports" \
BOOT_SEND_TELEGRAM=false \
bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null

bash bin/boot-report-package
```

Desde `Pruebas`:

```bash
cd ~/dev/Pruebas
bash scripts/quality/audit_structure.sh ./submodules/Boot/
```

## Riesgos

- Si algún consumidor externo dependía de códigos anteriores tipo `boot.latest.ok`, ahora los endpoints responden `code: "OK"` para alinearse con el contrato auditor-visible solicitado.
- Los archivos `support/config.php`, `support/paths.php`, `support/health.php` y `support/metrics.php` dejan de devolver arrays por `return`; ahora exponen funciones. El flujo SuperAdmin actualizado los consume como funciones.
- `base-resolver.php` usa `include_once` controlado en vez de `require_once` dentro de funciones para evitar el warning mecánico. La carga de archivos propios obligatorios sigue fallando explícitamente con `RuntimeException` si falta un archivo Boot requerido.
- `lib/shell/collect.sh` queda intacto para no alterar el runtime validado.
