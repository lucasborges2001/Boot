# Boot

`Boot` es un submódulo de observabilidad del servidor dependiente de `Base`.
Genera snapshots read-only del host, persiste `report.json` y `summary.txt`, envía opcionalmente un mensaje por Telegram usando las primitivas de Base y expone una UI/API para SuperAdmin.

## Responsabilidad

Boot conserva lógica específica del dominio servidor:

- hostname, kernel, uptime, red LAN;
- load promedio;
- RAM y disco raíz;
- updates pendientes y reboot requerido;
- servicios systemd fallidos;
- temperatura cuando existe;
- formatter de Telegram específico del reporte Boot;
- lectura de historial y exposición read-only.

No implementa helpers genéricos de env, JSON, log, lock, time ni Telegram. Eso vive en `Base/lib/shell` y `Base/back`.

## Uso rápido

```bash
cd ~/Escritorio/Proyectos/Pruebas/submodules/Boot
chmod +x bin/* scripts/server/*.sh scripts/web/*.sh scripts/dev/*.sh test/shell/*.sh
bash scripts/dev/smoke.sh
BOOT_REPORTS_DIR=/tmp/boot-report/reports BOOT_SEND_TELEGRAM=false bin/boot-report --no-telegram --print
```

## Contratos principales

- Último JSON: `/var/lib/boot-report/reports/latest/report.json`
- Último resumen: `/var/lib/boot-report/reports/latest/summary.txt`
- API pública: `public_html/api/{health,latest,history}.php`
- SuperAdmin: `public_html/superadmin/index.php`
