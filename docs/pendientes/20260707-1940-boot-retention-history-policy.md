# P1 — Completar política de retención e historial

## Estado verificado en main
**Parcialmente avanzado.** Existe `test/shell/boot_history_retention_test.sh`, incluido por el bucle de `scripts/dev/smoke.sh`. El test genera snapshots sintéticos, llama `boot_prune_old_reports`, comprueba límite de dos directorios, preservación de `latest`, exclusión de directorios ajenos y symlinks, y colisiones de timestamp.

Por tanto, la afirmación anterior de que falta crear un test de poda ya no es correcta. La presencia del test no demuestra que haya pasado en el SHA actual.

## Brechas pendientes
1. Verificar defaults, semántica y documentación de `BOOT_REPORT_RETENTION_DAYS` y cualquier límite por cantidad.
2. Comprobar límites efectivos de `history.php?limit=N`, incluidos valores inválidos y máximos.
3. Verificar retención por edad y cantidad, así como errores parciales y concurrencia en persistencia.
4. Decidir si SuperAdmin debe mostrar ventana retenida y número de snapshots, evitando duplicar lógica de backend.
5. Registrar ejecución de pruebas con SHA y dependencias exactas.

## Contratos e invariantes
- `latest` sigue disponible después de la poda.
- Nunca se siguen symlinks ni se eliminan rutas ajenas al directorio de reportes.
- API history mantiene límites acotados y shape documentado.
- La poda no interrumpe la escritura de un snapshot válido.

## Validación y cierre
- `BASE_DIR=../Base bash test/shell/boot_history_retention_test.sh`.
- `BASE_DIR=../Base bash scripts/dev/smoke.sh`.
- Prueba focalizada de API history y casos límite.
- Documentación operativa alineada con configuración efectiva.
- Cerrar únicamente con resultados observados y decisión explícita sobre visibilidad en SuperAdmin.

## No verificado
Ejecución real de tests, defaults productivos, concurrencia y UI.
