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
