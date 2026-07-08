# P1 — Agregar suite host/TestKit opcional

## Qué falta

Crear una validación desde `Pruebas` para cubrir `Boot` como submódulo de tooling opcional, sin convertirlo en preflight bloqueante.

## Evidencia revisada

`Pruebas/config/submodules.php` clasifica `Boot` como:

- `tier`: `tooling-server-bootstrap`;
- `required_for_preflight`: `false`;
- `include_in_app_deploy`: `false`;
- `tooling`: `true`;
- `optional`: `true`.

## Riesgo

Boot puede degradarse sin que el host lo detecte hasta la instalación real.

## Ruta sugerida

Agregar suite opcional, por ejemplo:

```txt
scripts/quality/boot_tooling_smoke.sh
```

Debe validar:

- submódulo inicializado;
- `bash scripts/dev/smoke.sh` dentro de Boot;
- generación local sin Telegram;
- API web con server PHP local;
- packaging si se cierra el pendiente P0.

## Verificación

```bash
cd Pruebas
bash scripts/quality/boot_tooling_smoke.sh
```

## Criterio de cierre

- La suite existe.
- No bloquea app deploy por defecto.
- Puede ejecutarse manualmente en CI/local.
- Documenta claramente que Boot es tooling opcional.
