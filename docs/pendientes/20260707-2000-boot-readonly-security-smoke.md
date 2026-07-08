# P1 — Smoke de seguridad read-only para UI/API

## Objetivo

Evitar que Boot derive accidentalmente en panel de ejecución remota.

## Motivo

Boot debe observar, no operar. La UI/API deben mantenerse read-only.

## Ruta sugerida

Crear smoke con grep negativo sobre `public_html`:

```bash
grep -RIn "shell_exec\|exec(\|system(\|passthru\|proc_open\|popen" public_html && exit 1 || true
grep -RIn "<form\|method=\"post\"\|method='post'" public_html && exit 1 || true
```

Agregar allowlist si aparece un falso positivo documentado.

## Criterio de cierre

- Smoke falla si aparece ejecución de comandos en UI/API.
- Smoke falla si aparece POST/formulario sin justificación.
- Queda integrado a `scripts/dev/smoke.sh` o suite dedicada.
