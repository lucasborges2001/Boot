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

## Revisión estática — 2026-11-02

**Estado: parcialmente implementado, pendiente de parametrización y tests.**

### Evidencia verificada

- `lib/python/build_report.py` ya calcula `status.severity`, `status.overall` y `status.summary` con prioridades `critical > warning > info > ok`.
- Umbrales fijos actuales: filesystem >=95% crítico / >=85% warning; RAM >=95% crítico / >=85% warning; CPU utilizada >=98% crítico / >=90% warning. Cualquier servicio fallido implica crítico.
- Updates de seguridad o reboot requerido generan warning; cualquier update pendiente o warnings de recolección generan info si no hay mayor severidad.
- Se recolectan load y temperatura, pero **no** participan en esta decisión de severidad. La ausencia de CPU/RAM/filesystem se registra en warnings de recolección, no se convierte automáticamente en crítico.
- `config/server.env.example` y `config/servidor.env.example` no definen perfiles `BOOT_WARN_*` / `BOOT_CRIT_*`. `test/php/BootTelemetryV2Test.php` verifica forma y valores de fixtures, no límites ni inyección de umbrales.

### Brecha y decisión técnica pendiente

- [ ] Definir matriz por señal: métricas porcentuales, load normalizado por CPUs, temperatura disponible/no disponible, updates, reboot y servicios fallidos.
- [ ] Diferenciar política de severidad de telemetría de futuras decisiones `safe_to_reboot` (no son equivalentes).
- [ ] Decidir configuración por variables `BOOT_WARN_*` / `BOOT_CRIT_*` o perfil explícito, con validación de tipos, rangos y orden `warn < crit`.
- [ ] Mantener defaults actuales o justificar los cambios mediante fixtures y compatibilidad con schema v1/v2.
- [ ] Definir qué hacer ante métricas `null`/no disponibles: no imputar 0 como lectura saludable y preservar evidencia de `unknown`.
- [ ] Exponer política efectiva de modo read-only, sin secretos, y cubrir compatibilidad de API/SuperAdmin.

### Pruebas y cierre

Tests deterministas de bordes: 84.99/85/94.99/95 en filesystem y RAM; 89.99/90/97.99/98 en CPU; servicios fallidos; updates/reboot; sensores no disponibles; valores inválidos y reversión a defaults. Verificar que cambiar una variable realmente cambie severidad y que no se rompa el contrato de `status`.

**PASS:** perfiles aplicados por código, contrato documentado y tests de límites con `unknown`; **FAIL:** solo documentar variables inexistentes o mostrar métricas sin evaluarlas.

**No verificado:** ejecución de pruebas, configuración efectiva en servidor, CI o comportamiento operativo.
