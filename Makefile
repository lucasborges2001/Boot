.PHONY: install uninstall start status logs

install:
	sudo ./scripts/install.sh

uninstall:
	sudo ./scripts/uninstall.sh

start:
	sudo systemctl start boot-report.service

status:
	systemctl status boot-report.service --no-pager

logs:
	journalctl -u boot-report.service -b --no-pager
