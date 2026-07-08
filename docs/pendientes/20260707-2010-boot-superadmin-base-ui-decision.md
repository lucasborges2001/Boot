# P2 — Decidir migración o excepción de UI Base

## Objetivo

Definir si SuperAdmin de Boot migra a componentes `Base` o queda como excepción documentada.

## Motivo

Boot usa UI propia. Esto puede ser aceptable por ser tooling server, pero conviene decidirlo para evitar deuda visual difusa.

## Opciones

### Opción A — Migrar a Base UI

- Cards de estado.
- Tabla de historial.
- Badges de severidad.
- Bloques de contrato/paths.

### Opción B — Documentar excepción

- Boot es herramienta de servidor.
- UI autónoma read-only.
- CSS propio permitido si no duplica contratos críticos.

## Criterio de cierre

- Decisión documentada.
- Si se migra, smokes siguen pasando.
- Si se exceptúa, `bootSuperadminFront.md` explica el motivo.
