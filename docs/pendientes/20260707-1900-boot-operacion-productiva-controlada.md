# P0 — Validar operación productiva controlada

## Objetivo

Confirmar que Boot funciona instalado con systemd, permisos reales, paths productivos y Telegram deshabilitado o validado con bot sandbox.

## Motivo

Los smokes locales pasan, pero aún falta evidencia de instalación real con:

- `/opt/boot-report`;
- `/var/lib/boot-report/reports`;
- timer `boot-report.timer`;
- unit `boot-report.service`;
- `Base` resuelto desde ruta productiva.

## Ruta sugerida

```bash
sudo BASE_DIR=/opt/base bash scripts/server/install.sh
sudo BOOT_SEND_TELEGRAM=false /opt/boot-report/bin/boot-report --no-telegram --print | python3 -m json.tool
sudo test -f /var/lib/boot-report/reports/latest/report.json
sudo test -f /var/lib/boot-report/reports/latest/summary.txt
systemctl status boot-report.timer --no-pager
journalctl -u boot-report.service --no-pager -n 120
```

## Criterio de cierre

- Timer activo.
- Último JSON válido.
- Último summary válido.
- API web lee snapshot real.
- Telegram queda probado con sandbox o deshabilitado explícitamente.
