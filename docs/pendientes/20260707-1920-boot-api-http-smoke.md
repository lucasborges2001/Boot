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
