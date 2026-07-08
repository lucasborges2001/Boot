# Checklist de auditoría de modularidad — Boot

## Estado de cierre

Último estado reportado:

```txt
Summary: 0 error(s), 1 warning(s), 0 info
```

Única advertencia aceptada temporalmente:

```txt
FILE_TOO_LARGE :: lib/shell/collect.sh
```

## P0 — Contrato estructural

- [x] Existe `docs/estructura-modulo.md`.
- [x] Existe `docs/contrato-host-modulo.md`.
- [x] Existe `docs/checklists/auditoria-modularidad-modulo.md`.
- [x] Boot queda documentado como tooling opcional.
- [x] Se explicita dependencia con `Base`.
- [x] Se explicita `required_for_preflight=false`.
- [x] Se explicita `include_in_app_deploy=false`.
- [x] UI/API quedan declaradas como read-only.

## P0 — Bash crítico legacy

- [x] `lib/render.sh` pasa a agregador chico compatible.
- [x] Funciones legacy de render se dividen en `lib/render/*.sh`.
- [x] `lib/system.sh` pasa a agregador chico compatible.
- [x] Funciones legacy de sistema se dividen en `lib/system/*.sh`.
- [x] Se conserva compatibilidad de nombres públicos.
- [x] Se confirma que el runtime vigente usa `lib/shell/*`.

## P0 — Packaging

- [x] `bin/boot-report-package` genera paquetes.
- [x] `scripts/server/package-server.sh` tolera rutas opcionales inexistentes.
- [x] `scripts/web/package-web.sh` tolera rutas opcionales inexistentes.
- [x] Existen manifests de packaging.
- [x] Existe smoke de packaging.
- [x] Validación reportada: `dist/boot-server.tar.gz` y `dist/boot-web.tar.gz` generados.

## P1 — API pública y SuperAdmin

- [x] Existe `_common.php` en API pública.
- [x] Existe `_common.php` en API SuperAdmin.
- [x] Endpoints aceptan solo `GET`.
- [x] Método incorrecto devuelve `405` y `Allow: GET`.
- [x] Cada endpoint contiene contrato JSON visible para el auditor.
- [x] Respuestas incluyen `ok`, `module`, `code`, `data` o `error`.
- [x] Existe `test/php/BootApiContractTest.php`.

## P1 — Headers y bootstrap

- [x] Archivos PHP modificados incluyen `declare(strict_types=1);` cuando aplica.
- [x] Archivos PHP modificados incluyen `@file` y `@brief` concretos.
- [x] JS SuperAdmin incluye header concreto.
- [x] Resolución de Base se separa en `back/support/base-resolver.php`.
- [x] `back/bootstrap.php` queda como orquestador chico.
- [x] No queda warning `PHP_REQUIRE_AFTER_CODE`.

## P1 — SuperAdmin

- [x] Existe `public_html/superadmin/bootSuperadminFront.md`.
- [x] Soportes SuperAdmin exponen funciones/view models, no wrappers de `return` directo.
- [x] `_pageBootstrap.php` tiene responsabilidad visible.
- [x] La pantalla queda documentada como read-only.

## Pendientes vivos

- [ ] Validar operación productiva controlada con systemd.
- [ ] Refactor controlado de `lib/shell/collect.sh`.
- [ ] Agregar smoke HTTP real para API pública/SuperAdmin.
- [ ] Agregar suite host opcional en `Pruebas`.
- [ ] Definir política de retención/historial.
- [ ] Endurecer smoke read-only de UI/API.
- [ ] Validar Telegram con bot sandbox o documentar no uso.
