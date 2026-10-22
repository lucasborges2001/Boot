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

## Preflight legacy y nuevo contrato de instalación (2026-10)

Antes de planificar un cambio, ejecutar en el host una auditoría read-only:

    python3 scripts/server/installation-doctor.py

El doctor devuelve JSON con classification=LEGACY_OR_DRIFT, INCOMPLETE o
CONTRACT_OK_DISK. Un contrato completo en disco NO demuestra que systemd
esté corriendo correctamente; runtime_verified permanece false. El status
de reporte exige schema Boot v1/v2 y freshness configurable.

La instalación actual de servidor es **distinta** del módulo v2: usa
/opt/boot-report/boot-report.sh con timer diario 08:30 y usuario bootreport.
El instalador actualizado bloquea la sobrescritura de la unidad legacy y
del ejecutable legacy, y no hace rsync --delete. Tampoco sobrescribe un
config/server.env existente; no da autorización para detener el servicio.

Para un cutover autorizado: inventariar scheduler, rutas, usuarios, permisos
y backup; preparar Base y el nuevo artefacto Boot; validar el doctor contra
una raíz de prueba; acordar ventana de mantenimiento; retirar/aislar el
servicio anterior mediante operación explícita; instalar nueva unidad y
medir snapshots frescos; revisar permisos del consumidor de solo lectura.
Rollback: restaurar unidad/script previo y reiniciar solo mediante runbook
de operación autorizado. No migrar datos ni regenerar secretos por default.
