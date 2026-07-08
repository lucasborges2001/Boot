# P1 — Formalizar retención e historial

## Objetivo

Asegurar que los snapshots históricos no crezcan indefinidamente y que la UI/API expliquen claramente qué retención aplican.

## Motivo

Boot persiste `latest` e historial. Falta una validación explícita de poda, límites y comportamiento con muchos reportes.

## Ruta sugerida

- Test de retención con más snapshots que `BOOT_REPORT_RETENTION_DAYS` o límite configurado.
- Verificar que `history.php?limit=N` respeta rango permitido.
- Documentar política de rotación.
- Exponer en SuperAdmin cuántos reportes hay y cuál es la ventana retenida.

## Criterio de cierre

- Test crea historial sintético y confirma poda.
- API history no devuelve listas no acotadas.
- Docs explican retención default y variable de configuración.
