# P1 — Alinear SuperAdmin con Base UI

## Qué falta

Evaluar si `public_html/superadmin` debe migrar a componentes `Base` o mantener una excepción documentada.

## Evidencia revisada

La pantalla actual usa:

- `public_html/superadmin/index.php` como layout propio;
- `boot-superadmin.css` propio;
- partials propios;
- helpers propios de escape/formato.

## Riesgo

El módulo puede quedar visualmente consistente por paleta, pero contractualmente separado del estándar de SuperAdmin usado por otros módulos del host.

## Ruta sugerida

1. Comparar con el patrón Base vigente para SuperAdmin.
2. Si existen componentes Base suficientes, migrar por fases:
   - status card;
   - métricas;
   - historial;
   - contratos/paths.
3. Si no conviene migrar, documentar excepción: `Boot` es tooling server y UI autónoma read-only.
4. Agregar smoke de no regresión visual/contrato.

## Verificación

```bash
grep -RIn "base_component\|base_ui\|base_superadmin" public_html/superadmin || true
grep -RIn "shell_exec\|exec(\|system(\|passthru\|proc_open" public_html/superadmin public_html/api || true
```

## Criterio de cierre

- Migración a Base aplicada, o excepción documentada y aceptada.
- UI sigue read-only.
- No aparecen formularios ni acciones de ejecución del sistema.
