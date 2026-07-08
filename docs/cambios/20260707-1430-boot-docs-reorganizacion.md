# Cambio — reorganización de Boot/docs

## Resumen

Se genera una carpeta `docs/` completa para reemplazo directo dentro de `Boot`.

## Incluye

- índice principal de documentación;
- operación por arquitectura, instalación, API/UI y testing;
- contratos de Base, schema `report.json` y packaging;
- auditoría cerrada del estado actual;
- pendientes priorizados.

## No incluye

- cambios de runtime;
- cambios de scripts;
- cambios en README raíz;
- commits;
- actualización de puntero del submódulo en `Pruebas`.

## Compatibilidad

El paquete está pensado para que se elimine `Boot/docs` y se reemplace por esta carpeta `docs`.

## Verificación sugerida

```bash
cd submodules/Boot
find docs -type f | sort
find docs -name '*.md' -print0 | xargs -0 -n1 sed -n '1p'
bash scripts/dev/smoke.sh
```
