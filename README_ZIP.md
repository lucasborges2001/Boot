# Boot P0/P1 hardening — ZIP de aplicación

## Resumen ejecutivo

Este paquete cierra los P0/P1 solicitados para `Boot` sin hacer commits, sin actualizar punteros de submódulo y sin tocar `README.md`.

Objetivos cubiertos:

- documentación estructural requerida por perfil `module`;
- reducción de `FILE_CRITICAL_SIZE` en `lib/render.sh` y `lib/system.sh` mediante agregadores compatibles;
- API read-only con `_common.php`, método `GET` y contrato JSON estable;
- headers PHP/JS concretos;
- bootstrap PHP más claro y con resolución de Base separada;
- packaging sin rutas inexistentes obligatorias;
- test productivo manual separado del smoke seguro.

## Aplicación

Desde la raíz de `Pruebas`:

```bash
unzip boot_p0_p1_hardening_package.zip -d .
cd submodules/Boot
chmod +x lib/render.sh lib/render/*.sh lib/system.sh lib/system/*.sh \
  scripts/server/package-server.sh scripts/web/package-web.sh scripts/test.sh \
  scripts/server/test-production.sh test/shell/*.sh
```

## Archivos nuevos/modificados incluidos

Ver listado completo con:

```bash
unzip -l boot_p0_p1_hardening_package.zip
```

Áreas principales:

- `docs/estructura-modulo.md`
- `docs/contrato-host-modulo.md`
- `docs/checklists/auditoria-modularidad-modulo.md`
- `lib/render.sh` y `lib/render/*.sh`
- `lib/system.sh` y `lib/system/*.sh`
- `public_html/api/_common.php`
- `public_html/superadmin/api/_common.php`
- endpoints API públicos y SuperAdmin
- `back/support/base-resolver.php`
- `back/bootstrap.php`
- `public_html/superadmin/bootSuperadminFront.md`
- `FILE_MANIFEST.md`
- `DELETE_MANIFEST.md`
- tests nuevos `BootApiContractTest`, `runtime_entrypoints_test`, `boot_packaging_test`

## Errores del auditor cerrados

Esperado:

- `DOC_REQUIRED_MISSING :: docs/checklists/auditoria-modularidad-modulo.md`
- `DOC_REQUIRED_MISSING :: docs/contrato-host-modulo.md`
- `DOC_REQUIRED_MISSING :: docs/estructura-modulo.md`
- `FILE_CRITICAL_SIZE :: lib/render.sh`
- `FILE_CRITICAL_SIZE :: lib/system.sh`

## Warnings reducidos o justificados

Reducidos:

- `PHP_HEADER_MISSING` en archivos PHP modificados.
- `PHP_REQUIRE_AFTER_CODE :: back/bootstrap.php` al mover resolución compatible a `back/support/base-resolver.php`.
- `API_COMMON_MISSING`, `API_METHOD_GUARD_MISSING`, `API_JSON_CONTRACT_WEAK` en endpoints principales.
- `MODULE_DOC_MISSING :: public_html/superadmin` con `bootSuperadminFront.md`.
- `JS_HEADER_MISSING` en `boot-superadmin.js`.
- `SH_SUDO_USAGE :: scripts/test.sh` al dejarlo como wrapper seguro.

Justificado/fuera de fase:

- `FILE_TOO_LARGE :: lib/shell/collect.sh` queda como deuda P1/P2 porque es runtime vigente y requiere refactor con fixtures específicos.
- Migración visual total a Base UI queda pendiente para no cambiar comportamiento funcional.

## Comandos de verificación

Desde `Pruebas`:

```bash
git status --short
bash scripts/quality/audit_structure.sh ./submodules/Boot/
```

Desde `Boot`:

```bash
find . -name '*.php' -print0 | xargs -0 -n1 php -l
bash scripts/dev/smoke.sh
BOOT_REPORTS_DIR="$(mktemp -d)/reports" BOOT_SEND_TELEGRAM=false bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null
bash bin/boot-report-package
```

API por CLI:

```bash
php public_html/api/health.php | python3 -m json.tool >/dev/null
php public_html/api/latest.php | python3 -m json.tool >/dev/null || true
php public_html/api/history.php | python3 -m json.tool >/dev/null
php test/php/BootApiContractTest.php
```

Secretos:

```bash
grep -RIn "TELEGRAM_BOT_TOKEN=.*[A-Za-z0-9_]\{20,\}\|TELEGRAM_CHAT_ID=.*[0-9]\{5,\}" . \
  --exclude-dir=.git \
  --exclude-dir=dist || true
```

## Riesgos de integración

- Los endpoints ahora envuelven la respuesta en `data`; si algún consumidor externo esperaba el payload antiguo plano, debe ajustarse.
- `back/support/base-resolver.php` conserva resolución dinámica de `Base`; validar en el layout real `Pruebas/submodules/Base`.
- `scripts/server/test-production.sh` puede usar Telegram real y systemd; no ejecutarlo en CI ni sin intención operativa.
- El auditor real debe correrse localmente porque este ZIP fue armado por lectura remota del repo y validación sintáctica local, no sobre el checkout completo con `Base` real.
