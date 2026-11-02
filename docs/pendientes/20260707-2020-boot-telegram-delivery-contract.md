# P1 — Contrato de entrega Telegram sandbox

## Objetivo

Validar Telegram sin depender de credenciales reales ni chat productivo.

## Motivo

Telegram es salida opcional. El CLI debe funcionar sin Telegram, pero si se habilita debe fallar de forma legible ante token/chat inválido.

## Ruta sugerida

- Definir bot sandbox para pruebas manuales.
- Documentar variables mínimas.
- Validar `getMe` y envío de mensaje de test.
- Confirmar que `BOOT_SEND_TELEGRAM=false` evita llamadas externas.
- Confirmar que errores de Telegram se registran en JSON sin romper persistencia.

## Criterio de cierre

- Test manual productivo documentado.
- Evidencia de mensaje recibido o decisión explícita de no usar Telegram.
- No se versiona ningún secreto.

## Revisión estática — 2026-11-02

**Estado: parcialmente implementado; entrega sandbox y fallos reales no validados.**

### Evidencia verificada

- `bin/boot-report` usa `Base/lib/shell/telegram.sh` y solo llama a `base_telegram_send_html` cuando `BOOT_SEND_TELEGRAM` se evalúa como verdadero y no se usa `--no-telegram`.
- Captura exit code y respuesta, asigna `telegram.last_send_ok`, `telegram.message_id` y `telegram.description` mediante `lib/python/set_telegram_result.py`, y después persiste el reporte.
- `test/shell/boot_render_test.sh` cubre el formato HTML del resumen, no la entrega HTTP.
- `config/servidor.env.example` declara `BOOT_SEND_TELEGRAM=false`; el ejemplo legacy `config/server.env.example` lo declara `true`. **Los defaults son distintos según despliegue** y el CLI aplica `true` por defecto cuando no se configura: verificar política segura antes de operar.
- Base implementa `sendMessage` con timeout, retries y parseo de respuesta; no se observó prueba de `getMe` ni fixture HTTP del ciclo Boot → Base → JSON.

### Brechas concretas

- [ ] Test con mock de `base_telegram_send_html` que confirme cero llamadas en modo deshabilitado y `--no-telegram`.
- [ ] Fixtures de éxito, error de API, timeout, credenciales ausentes, `curl` ausente y respuesta inválida; validar persistencia y exit code del CLI.
- [ ] Comprobar que un error de Telegram no destruye el snapshot ni oculta un error previo de recolección/persistencia.
- [ ] Validar en sandbox real `getMe` y `sendMessage` con evidencia saneada, sin incluir token, chat ID, URL con token, cuerpos privados o variables de entorno en logs.
- [ ] Documentar decisión operacional por despliegue: Telegram opt-in o explícitamente deshabilitado; diferenciar legacy de `servidor`.
- [ ] Definir protección ante duplicados/retries y criterios de notificación, sin mezclar entrega con severidad.

### Contrato de salida esperado

`telegram.enabled=false` implica no enviar; `last_send_ok=null` indica que no hubo intento; `true/false` representan respuesta del intento. La entrega es opcional: el fallo del canal debe quedar explícito, sin convertir un reporte válido en un supuesto fallo de producto.

**PASS:** pruebas aisladas que verifican rama deshabilitada, respuestas, retries y persistencia más una validación manual sandbox saneada (o decisión documentada de no usar Telegram). **No verificado:** entrega a Telegram, recepción de mensajes, CI ni operación real.
