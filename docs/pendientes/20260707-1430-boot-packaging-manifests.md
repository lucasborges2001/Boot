# P0 — Corregir manifests de packaging

## Qué falta

Verificar y corregir el contrato de packaging porque `scripts/server/package-server.sh` y `scripts/web/package-web.sh` referencian manifests documentales que no fueron verificados como existentes:

```txt
FILE_MANIFEST.md
DELETE_MANIFEST.md
```

## Evidencia revisada

- `bin/boot-report-package` llama a `scripts/server/package-server.sh` y `scripts/web/package-web.sh`.
- `scripts/server/package-server.sh` incluye `FILE_MANIFEST.md` y `DELETE_MANIFEST.md` en el tar server.
- `scripts/web/package-web.sh` incluye `FILE_MANIFEST.md` en el tar web.

## Riesgo

Si esos archivos no existen en el checkout real, `tar` puede fallar y bloquear la generación de paquetes.

## Ruta sugerida

1. Ejecutar `bin/boot-report-package`.
2. Si falla por manifests, decidir:
   - crear manifests vivos;
   - removerlos de los scripts;
   - mover el contrato a `docs/contratos/packaging.md` y actualizar scripts.
3. Agregar smoke que ejecute packaging.

## Verificación

```bash
cd submodules/Boot
bin/boot-report-package
ls -lh dist/boot-server.tar.gz dist/boot-web.tar.gz
```

## Criterio de cierre

- Packaging corre con exit code `0`.
- Los dos tarballs existen.
- El smoke falla si vuelve a faltar un archivo referenciado por los scripts de paquete.
