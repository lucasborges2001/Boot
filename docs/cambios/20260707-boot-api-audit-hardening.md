# Cambio — Boot API audit hardening post P0/P1

## Resumen

Esta fase endurece señales mecánicas que el auditor estructural seguía reportando después del cierre P0/P1.

## Cambios aplicados

- Endpoints públicos y SuperAdmin llaman explícitamente `boot_api_require_method('GET', ...)`.
- Endpoints responden con `boot_api_send_ok(...)` y `boot_api_send_error(...)`.
- El contrato JSON queda normalizado como:
  - éxito: `ok`, `module`, `code`, `data`;
  - error: `ok`, `module`, `code`, `error.message`.
- `METHOD_NOT_ALLOWED` devuelve HTTP 405 y header `Allow: GET` en contexto web.
- `back/support/base-resolver.php` evita `require_once` después de código y encapsula carga condicional con `include_once` validado.
- Soportes SuperAdmin `config`, `paths`, `health` y `metrics` pasan de wrappers de retorno a fronteras con view models concretos.

## Warnings objetivo

- `API_METHOD_GUARD_MISSING` en endpoints API.
- `API_JSON_CONTRACT_WEAK` en endpoints API.
- `PHP_REQUIRE_AFTER_CODE` en `back/support/base-resolver.php`.
- `PHP_HEADER_MISSING` en soportes SuperAdmin.
- `WRAPPER_SUSPECT` en soportes SuperAdmin y `_pageBootstrap.php`.

## Fuera de alcance

`lib/shell/collect.sh` queda como pendiente P2 porque concentra recolección de métricas reales del host y cualquier extracción requiere fixtures dedicados para no alterar el shape de `report.json`.
