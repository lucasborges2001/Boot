# P0 — Validar operación productiva controlada

## Qué falta

Cerrar una validación real de Boot instalado con systemd y, si corresponde, Telegram con credenciales de prueba.

## Evidencia revisada

Existe instalador server, unit `oneshot`, timer periódico, configuración `server.env.example` y CLI con `--no-telegram`.

## Riesgo

La operación local puede pasar, pero producción puede fallar por:

- `BASE_DIR` incorrecto;
- permisos de `/var/lib/boot-report/reports`;
- falta de `rsync`;
- secretos Telegram vacíos;
- permisos del bot o `CHAT_ID` incorrecto;
- restricciones systemd de hardening.

## Ruta sugerida

1. Instalar en servidor controlado.
2. Ejecutar sin Telegram.
3. Confirmar artefactos.
4. Activar Telegram con bot de prueba.
5. Confirmar mensaje recibido.
6. Dejar `BOOT_SEND_TELEGRAM=false` si no corresponde notificar.

## Verificación

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
- API web lee el snapshot real.
- Telegram probado o deshabilitado explícitamente.
