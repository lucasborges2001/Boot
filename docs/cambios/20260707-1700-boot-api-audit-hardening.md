# Cambio — Boot API audit hardening

## Resumen

Endurecimiento de API pública y API SuperAdmin para satisfacer auditor y contrato read-only.

## Cierres

- `_common.php` en API pública.
- `_common.php` en API SuperAdmin.
- Guard visible de método `GET`.
- `405` con `Allow: GET` para métodos inválidos.
- Wrappers JSON.
- Headers PHP y JS.
- View models en soportes SuperAdmin.
- `back/support/base-resolver.php` sin warning de `require_once` después de código.

## Estado posterior

La fase eliminó warnings de método, wrappers sospechosos y headers; quedó pendiente hacer el contrato JSON más visible en cada endpoint.
