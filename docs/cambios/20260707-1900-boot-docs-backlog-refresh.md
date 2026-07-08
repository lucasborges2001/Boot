# Cambio — refresh de documentación y pendientes post P0/P1

## Resumen

Se reemplaza `Boot/docs` con una versión actualizada al estado real post hardening.

## Decisiones

- Packaging pasa de pendiente a cambio cerrado.
- API JSON visible pasa de pendiente a cambio cerrado.
- Docs requeridos por auditor quedan como contrato estructural vigente.
- Pendientes vivos se reorganizan por valor operativo posterior, no por warnings ya cerrados.
- `lib/shell/collect.sh` queda como única deuda estructural aceptada temporalmente.

## Validación base

Este refresh toma como punto de partida el estado reportado:

```txt
Summary: 0 error(s), 1 warning(s), 0 info
```
