# P1 — Perfiles de umbrales y severidad

## Objetivo

Hacer explícita y testeable la política de severidad para load, RAM, disco, temperatura, updates y servicios fallidos.

## Motivo

Boot reporta severidad, pero para uso real conviene poder adaptar umbrales por servidor sin editar código.

## Ruta sugerida

- Definir variables `BOOT_WARN_*` y `BOOT_CRIT_*` documentadas.
- Agregar fixture de severidad OK/WARN/CRIT.
- Mostrar umbrales activos en `summary.txt` o SuperAdmin.
- Evitar falsos positivos en servidores chicos o con sensores ausentes.

## Criterio de cierre

- Los umbrales tienen defaults seguros.
- Tests cubren límites.
- Cambiar un umbral por env modifica la severidad esperada sin tocar código.
