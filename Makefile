.PHONY: install uninstall start restart status logs logs-tail test test-force force direct

install:
	sudo ./scripts/install.sh

uninstall:
	sudo ./scripts/uninstall.sh

start:
	sudo systemctl start boot-report.service

restart:
	sudo systemctl restart boot-report.service

status:
	systemctl status boot-report.service --no-pager

logs:
	journalctl -u boot-report.service -b --no-pager -n 200

logs-tail:
	journalctl -u boot-report.service -f

# Prueba normal (puede no enviar si ya corrió hoy)
test:
	sudo ./scripts/test.sh

# Prueba forzada (borra el stamp diario antes)
test-force:
	sudo ./scripts/test.sh --force

# Fuerza que el próximo start envíe
force:
	sudo rm -f /var/lib/boot-report/last_run_date

# Ejecuta el script directo como bootreport (sin systemd)
direct:
	sudo ./scripts/test.sh --direct --force --no-telegram-test
