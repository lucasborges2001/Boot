# Pendientes

Backlog vivo de `Boot`, actualizado después del cierre P0/P1.

Formato:

```txt
YYYYMMDD-HHMM-<slug>.md
```

## Resumen por prioridad

| Archivo | Prioridad | Área | Estado |
|---|---:|---|---|
| [`20260707-1900-boot-operacion-productiva-controlada.md`](20260707-1900-boot-operacion-productiva-controlada.md) | P0 | Producción | Abierto. |
| [`20260707-1920-boot-api-http-smoke.md`](20260707-1920-boot-api-http-smoke.md) | P1 | API/testing | Parcial: guard GET/405 existente; falta smoke HTTP real. |
| [`20260707-1930-boot-host-quality-suite.md`](20260707-1930-boot-host-quality-suite.md) | P1 | Host/TestKit | Parcial: smoke local existente; suite host no verificada. |
| [`20260707-1940-boot-retention-history-policy.md`](20260707-1940-boot-retention-history-policy.md) | P1 | Retención | Parcial: test de poda existente; faltan validaciones de límites y operación. |
| [`20260707-1950-boot-alert-threshold-profiles.md`](20260707-1950-boot-alert-threshold-profiles.md) | P1 | Alertas | Abierto. |
| [`20260707-2000-boot-readonly-security-smoke.md`](20260707-2000-boot-readonly-security-smoke.md) | P1 | Seguridad defensiva | Abierto: falta smoke read-only y auditoría de rutas indirectas. |
| [`20260707-2020-boot-telegram-delivery-contract.md`](20260707-2020-boot-telegram-delivery-contract.md) | P1 | Telegram | Abierto. |
| [`20260707-1910-boot-collect-shell-refactor.md`](20260707-1910-boot-collect-shell-refactor.md) | P2 | Auditor/runtime | Parcial: colectores extraídos; falta reevaluar auditor y contratos. |
| [`20260707-2010-boot-superadmin-base-ui-decision.md`](20260707-2010-boot-superadmin-base-ui-decision.md) | P2 | UX/Base | Abierto. |

## Pendientes cerrados y no listados

Ya no figuran como pendientes vivos:

- documentación estructural requerida;
- packaging manifests;
- `lib/render.sh` crítico;
- `lib/system.sh` crítico;
- API method guards;
- API JSON visible;
- headers/declare mecánicos;
- wrappers sospechosos SuperAdmin.

Esos temas pasan a `docs/cambios/` y `docs/auditorias/`.

## Salud del host antes del reinicio

El bloque [`salud-host-pre-reinicio/`](salud-host-pre-reinicio/01_alcance_y_criterios.md) sigue **abierto**. Revisión estática de `main` (2026-11-02): existen colectores y contratos generales de Boot, pero no se identifican la CLI `bin/boot-health` ni los tests específicos propuestos. Se actualizaron las fases 01, 06, 07 y 08 con evidencia, brechas y criterios PASS/FAIL. Las fases 02–05 conservan su estado pendiente hasta revisión detallada. No se ejecutaron tests ni validación productiva.
