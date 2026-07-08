# Checklist de auditoría de modularidad — Boot

## P0 — Contrato estructural

- [x] Existe `docs/estructura-modulo.md`.
- [x] Existe `docs/contrato-host-modulo.md`.
- [x] Existe `docs/checklists/auditoria-modularidad-modulo.md`.
- [x] Boot queda documentado como tooling opcional, no runtime app.
- [x] Se explicita dependencia con `Base`.
- [x] Se explicita `required_for_preflight=false`.
- [x] Se explicita `include_in_app_deploy=false`.
- [x] UI/API quedan declaradas como read-only.

## P0 — Bash crítico

- [x] `lib/render.sh` pasa de archivo monolítico crítico a agregador chico compatible.
- [x] Funciones legacy de render se dividen en `lib/render/*.sh`.
- [x] `lib/system.sh` pasa de archivo monolítico crítico a agregador chico compatible.
- [x] Funciones legacy de sistema se dividen en `lib/system/*.sh`.
- [x] Se conserva compatibilidad de nombres públicos.
- [x] Se agrega test de entrypoints runtime para confirmar que el CLI vigente usa `lib/shell/*`.

## P0 — Packaging

- [x] `bin/boot-report-package` sigue orquestando server + web.
- [x] `scripts/server/package-server.sh` evita fallar por rutas opcionales inexistentes.
- [x] `scripts/web/package-web.sh` evita fallar por rutas opcionales inexistentes.
- [x] Se crean `FILE_MANIFEST.md` y `DELETE_MANIFEST.md`.
- [x] Se agrega smoke `test/shell/boot_packaging_test.sh`.

## P1 — API

- [x] Existe `public_html/api/_common.php`.
- [x] Existe `public_html/superadmin/api/_common.php`.
- [x] Endpoints aceptan solo `GET`.
- [x] Método incorrecto devuelve `405` y contrato JSON estable.
- [x] Respuestas incluyen `ok`, `module`, `code` y `data` o `error`.
- [x] Se agrega `test/php/BootApiContractTest.php`.

## P1 — Headers mecánicos

- [x] Archivos PHP modificados incluyen `declare(strict_types=1);`.
- [x] Archivos PHP modificados incluyen `@file` y `@brief` concretos.
- [x] JS SuperAdmin incluye header concreto.

## P1 — Bootstrap

- [x] Resolución de Base se separa en `back/support/base-resolver.php`.
- [x] `back/bootstrap.php` queda como orquestador chico.
- [x] La carga dinámica compatible queda encapsulada en funciones.

## P1 — SuperAdmin

- [x] Se agrega `public_html/superadmin/bootSuperadminFront.md`.
- [x] Se documenta estructura de partials.
- [x] Se documentan endpoints usados.
- [x] Se declara que la pantalla no ejecuta comandos del sistema.

## P1 — Tests productivos

- [x] `scripts/test.sh` queda como wrapper seguro.
- [x] Test manual productivo se separa como `scripts/server/test-production.sh`.
- [x] `docs/operacion/testing.md` diferencia smoke seguro de test productivo.

## Pendientes fuera de esta fase

- [ ] Refactor fino de `lib/shell/collect.sh` si el auditor sigue marcando `FILE_TOO_LARGE` P1/P2.
- [ ] Migración visual completa de SuperAdmin a componentes Base si se decide homogeneizar UI.
- [ ] CI host que ejecute packaging y API con servidor HTTP real.

## P1 — Hardening post auditor

- [x] Endpoints públicos contienen llamada explícita a `boot_api_require_method('GET', ...)`.
- [x] Endpoints SuperAdmin contienen llamada explícita a `boot_api_require_method('GET', ...)`.
- [x] Endpoints responden con wrappers `boot_api_send_ok` / `boot_api_send_error`.
- [x] Error de método usa `METHOD_NOT_ALLOWED`, HTTP 405 y `Allow: GET`.
- [x] `back/support/base-resolver.php` no usa `require_once` después de código.
- [x] Soportes SuperAdmin tienen headers `@file` / `@brief`.
- [x] Soportes SuperAdmin pasan de wrappers de `return` a view models concretos.
- [x] `lib/shell/collect.sh` queda documentado como P2 separado.
