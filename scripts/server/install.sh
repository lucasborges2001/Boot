#!/usr/bin/env bash
set -euo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST_DIR="${BOOT_INSTALL_DIR:-/opt/boot-report}"
REPORTS_DIR="${BOOT_REPORTS_DIR:-/var/lib/boot-report/reports}"
BASE_DIR_VALUE="${BASE_DIR:-/opt/base}"
mkdir -p "$DEST_DIR" "$REPORTS_DIR" /etc/boot-report
rsync -a --delete --exclude='.git' --exclude='dist' "$SRC_DIR/" "$DEST_DIR/"
chmod +x "$DEST_DIR/bin/"* "$DEST_DIR/scripts/server/"*.sh "$DEST_DIR/scripts/web/"*.sh "$DEST_DIR/scripts/dev/"*.sh || true
if [[ ! -f "$DEST_DIR/config/server.env" ]]; then
  cp "$DEST_DIR/config/server.env.example" "$DEST_DIR/config/server.env"
  sed -i "s#^BASE_DIR=.*#BASE_DIR=$BASE_DIR_VALUE#" "$DEST_DIR/config/server.env" 2>/dev/null || true
fi
cp "$DEST_DIR/systemd/boot-report.service" /etc/systemd/system/boot-report.service
cp "$DEST_DIR/systemd/boot-report.timer" /etc/systemd/system/boot-report.timer
systemctl daemon-reload
systemctl enable --now boot-report.timer
printf 'Installed Boot report in %s. Configure secrets in %s/config/server.env or /etc/boot-report/boot-report.env.\n' "$DEST_DIR" "$DEST_DIR"
