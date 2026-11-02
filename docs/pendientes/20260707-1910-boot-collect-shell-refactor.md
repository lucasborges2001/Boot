# P2 — Completar refactor controlado de `lib/shell/collect.sh`

## Estado verificado en main
**Parcialmente avanzado.** El agregador ya delega en `lib/shell/collect/{system,cpu,memory,storage,network}.sh`; también existen tests focalizados `boot_collect_test.sh`, `boot_cpu_memory_test.sh`, `boot_network_rates_test.sh` y `boot_system_collect_test.sh`.

Esto contradice el plan original de comenzar la extracción desde cero. No se ha verificado que el auditor siga emitiendo `FILE_TOO_LARGE` ni que el refactor restante sea necesario.

## Brecha y decisión pendiente
1. Ejecutar auditor estructural y registrar warning exacto sobre el SHA actual.
2. Revisar tamaño, responsabilidades y contratos del agregador actual antes de proponer nuevas particiones.
3. Si el warning persiste y el tamaño refleja acoplamiento real, extraer solo responsabilidades justificadas, conservando funciones públicas y esquema JSON.
4. Ampliar fixtures únicamente donde falten casos reproducibles.

## Riesgos
Cambiar el orden de recolección, la semántica de valores ausentes o los campos de `report.json`; introducir dependencia indebida con Base.

## Validación y cierre
- `bash -n lib/shell/collect.sh` y scripts extraídos.
- `BASE_DIR=../Base bash scripts/dev/smoke.sh` con Base disponible.
- Comparación de JSON normalizado antes/después y contratos v1/v2.
- Evidencia del auditor sin el warning o justificación documentada para conservarlo.
- No cerrar hasta ejecutar pruebas y registrar SHA/resultados.

## No verificado
Auditor actual, ejecución de pruebas, comportamiento en host real.
