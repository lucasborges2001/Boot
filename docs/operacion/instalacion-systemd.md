# Instalación systemd

## Objetivo

Instalar `Boot` como servicio `oneshot` ejecutado por timer para generar snapshots periódicos del servidor.

## Requisitos

- Linux con `systemd`.
- `bash`, `php`, `python3` para validaciones locales.
- `rsync` para `scripts/server/install.sh`.
- `Base` disponible en `/opt/base` o vía `BASE_DIR`.
- Opcionales: `systemctl`, `sensors`, `apt`, `dnf`, `yum`, `pacman`.

## Instalación

```bash
cd submodules/Boot
sudo BASE_DIR=/opt/base bash scripts/server/install.sh
sudo nano /opt/boot-report/config/server.env
sudo systemctl restart boot-report.timer
```

El instalador copia el repo a `/opt/boot-report`, crea `/var/lib/boot-report/reports`, instala `boot-report.service` y `boot-report.timer`, y habilita el timer.

## Configuración

Archivo recomendado:

```txt
/opt/boot-report/config/server.env
```

Alternativa externa:

```txt
/etc/boot-report/boot-report.env
```

Variables sensibles:

```bash
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
```

No guardar secretos en Git.

## Timer

El timer auditado ejecuta el servicio al arrancar y luego cada 15 minutos:

```ini
OnBootSec=2min
OnUnitActiveSec=15min
AccuracySec=30s
Persistent=true
```

## Verificación post-instalación

```bash
systemctl status boot-report.timer --no-pager
systemctl list-timers --all | grep boot-report
sudo systemctl start boot-report.service
journalctl -u boot-report.service --no-pager -n 120
sudo test -f /var/lib/boot-report/reports/latest/report.json
sudo test -f /var/lib/boot-report/reports/latest/summary.txt
```

## Ejecución manual sin Telegram

```bash
sudo BOOT_SEND_TELEGRAM=false /opt/boot-report/bin/boot-report --no-telegram --print | python3 -m json.tool
```

## Desinstalación

```bash
sudo bash /opt/boot-report/scripts/server/uninstall.sh
```

Por defecto preserva reportes. Para borrar reportes:

```bash
sudo bash /opt/boot-report/scripts/server/uninstall.sh --purge-reports
```

## Criterio de cierre productivo

La instalación queda cerrada cuando:

- el timer está activo;
- existe `reports/latest/report.json` válido;
- existe `reports/latest/summary.txt`;
- `latest.php` responde JSON válido desde el entorno web;
- Telegram fue probado con secretos reales o quedó explícitamente deshabilitado.
