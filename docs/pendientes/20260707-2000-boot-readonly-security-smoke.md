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

## Auditoría estática — 2026-11-02

**Estado: abierto.** Existen endpoints públicos/SuperAdmin y tests de contratos, pero el árbol de `main` no identifica un smoke dedicado de frontera read-only. No se ha probado que todas las rutas web carezcan de ejecución de comandos o mutaciones.

**Corrección de diseño del smoke propuesto:** el grep con `&& exit 1 || true` puede ocultar errores y sus patrones generan falsos positivos en comentarios o nombres. La ausencia de cadenas `exec(` tampoco demuestra seguridad: deben revisarse includes, wrappers, funciones dinámicas, escritura de archivos y llamadas indirectas. Definir allowlist mínima justificada y revisar endpoints POST/formularios según contrato.

**PASS:** auditoría estática focalizada más test negativo que falla ante capacidades de ejecución/mutación añadidas; inspección de rutas transitivas y contratos GET. **No verificado:** ejecución de smokes, revisión completa de call graph ni pruebas de seguridad dinámicas.
