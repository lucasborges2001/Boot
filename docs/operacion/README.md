# Operación

Documentación operativa de `Boot`.

| Documento | Propósito |
|---|---|
| [`arquitectura.md`](arquitectura.md) | Explica responsabilidades, flujo runtime y límites. |
| [`instalacion-systemd.md`](instalacion-systemd.md) | Instalación server, timer y configuración. |
| [`superadmin-api.md`](superadmin-api.md) | API read-only y UI SuperAdmin. |
| [`testing.md`](testing.md) | Validaciones reproducibles y smoke tests. |

## Principio operativo

`Boot` debe degradar con valores neutros cuando faltan herramientas opcionales del host. `systemctl`, `sensors`, `apt`, `dnf`, `yum` o `pacman` no deben ser asumidos como siempre disponibles.

## Variables críticas

| Variable | Uso |
|---|---|
| `BASE_DIR` | Ruta hacia `Base`. Producción recomendada: `/opt/base`. |
| `BOOT_ENABLED` | Habilita/deshabilita generación de reportes. |
| `BOOT_REPORTS_DIR` | Directorio de snapshots. Default: `/var/lib/boot-report/reports`. |
| `BOOT_RETENTION_DAYS` | Retención de snapshots históricos. Default: `14`. |
| `BOOT_SEND_TELEGRAM` | Controla envío Telegram. |
| `TELEGRAM_BOT_TOKEN` | Secreto del bot. No versionar. |
| `TELEGRAM_CHAT_ID` | Destino Telegram. No versionar. |
