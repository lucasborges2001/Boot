# DELETE_MANIFEST — Boot

No hay borrados automáticos requeridos por este paquete.

Cambios relevantes:

- `lib/render.sh` se reemplaza por agregador compatible y se agregan módulos en `lib/render/`.
- `lib/system.sh` se reemplaza por agregador compatible y se agregan módulos en `lib/system/`.
- `scripts/test.sh` se mantiene como wrapper seguro.
- La prueba productiva manual queda en `scripts/server/test-production.sh`.

Si en una instalación existe documentación o scripts legacy fuera de estas rutas, revisar manualmente antes de borrar.
