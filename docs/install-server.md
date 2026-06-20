# Instalación en servidor

Convención elegida:

- App: `/opt/boot-report`
- Reports: `/var/lib/boot-report/reports`
- Env principal: `/opt/boot-report/config/server.env`
- Env alternativo: `/etc/boot-report/boot-report.env`
- Service: `/etc/systemd/system/boot-report.service`
- Timer: `/etc/systemd/system/boot-report.timer`

El service ejecuta `/opt/boot-report/bin/boot-report` cada 15 minutos mediante timer.
