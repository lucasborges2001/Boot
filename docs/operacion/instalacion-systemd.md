# Instalación con systemd

## Propósito

Validar Boot en entorno controlado con timer y permisos reales.

## Comandos base

```bash
sudo BASE_DIR=/opt/base bash scripts/server/install.sh
systemctl status boot-report.timer --no-pager
journalctl -u boot-report.service --no-pager -n 120
```

## Validación sin Telegram

```bash
sudo BOOT_SEND_TELEGRAM=false /opt/boot-report/bin/boot-report --no-telegram --print | python3 -m json.tool
sudo test -f /var/lib/boot-report/reports/latest/report.json
sudo test -f /var/lib/boot-report/reports/latest/summary.txt
```

## Validación con Telegram sandbox

Solo ejecutar si existe bot de prueba y `CHAT_ID` controlado.

```bash
sudo scripts/server/test-production.sh --force
```

## Riesgos

- `BASE_DIR` incorrecto.
- Permisos sobre `/var/lib/boot-report`.
- Secrets Telegram inválidos.
- Restricciones systemd de hardening.
- Falta de salida a internet.

## Regla

La validación productiva no forma parte del smoke automático.
