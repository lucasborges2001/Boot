#!/usr/bin/env bash
set -euo pipefail
DEST_DIR="${BOOT_INSTALL_DIR:-/opt/boot-report}"
REPORTS_DIR="${BOOT_REPORTS_DIR:-/var/lib/boot-report/reports}"
systemctl disable --now boot-report.timer 2>/dev/null || true
rm -f /etc/systemd/system/boot-report.service /etc/systemd/system/boot-report.timer
systemctl daemon-reload 2>/dev/null || true
rm -rf "$DEST_DIR"
if [[ "${1:-}" == "--purge-reports" ]]; then
  rm -rf "$REPORTS_DIR"
else
  printf 'Reports preserved at %s. Pass --purge-reports to remove them.\n' "$REPORTS_DIR"
fi
