# P1 — Agregar smoke HTTP real para API pública y SuperAdmin

## Objetivo

Cubrir endpoints con servidor PHP local, no solo tests por inclusión directa.

## Motivo

La API ya tiene contrato JSON visible, pero conviene validar headers/status HTTP reales.

## Cobertura sugerida

- `GET /api/health.php` responde JSON.
- `GET /api/latest.php` responde `200` o `404` con shape estable.
- `GET /api/history.php?limit=5` responde shape estable.
- `POST` a cada endpoint devuelve `405` y `Allow: GET`.
- SuperAdmin API replica el contrato.

## Ruta sugerida

Crear:

```txt
test/shell/boot_api_http_smoke.sh
```

con server temporal:

```bash
php -S 127.0.0.1:0 -t public_html
```

## Criterio de cierre

- El smoke falla ante HTML en vez de JSON.
- El smoke valida `405` real.
- El smoke se integra a `scripts/dev/smoke.sh` si no introduce flakiness.

## Auditoría estática — 2026-11-02

**Estado: abierto, con infraestructura HTTP parcial ya existente.** Se verificó que `public_html/api/_common.php` implementa `boot_api_require_get()`, respuestas JSON, estado 405 y header `Allow: GET`. Existen `test/php/BootApiContractTest.php` y endpoints públicos y SuperAdmin. Esto **no demuestra** el comportamiento con servidor HTTP real.

**Gap:** el árbol de `main` no contiene `test/shell/boot_api_http_smoke.sh`; `scripts/dev/smoke.sh` ejecuta tests shell/PHP existentes, pero no inicia un servidor HTTP. Probar GET/POST, Content-Type, status, body y ausencia de HTML, con servidor local aislado y puerto asignado de forma robusta (no asumir que `php -S 127.0.0.1:0` funciona en todos los entornos).

**PASS:** test reproducible con respuestas reales 200/404/405 y `Allow: GET`, sin dependencia de servicios externos. **No verificado:** ejecución de tests, headers reales ni respuesta en producción.
