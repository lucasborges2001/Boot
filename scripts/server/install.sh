#!/usr/bin/env bash
set -euo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST_DIR="${BOOT_INSTALL_DIR:-/opt/boot-report}"
REPORTS_DIR="${BOOT_REPORTS_DIR:-/var/lib/boot-report/reports}"
BASE_DIR_VALUE="${BASE_DIR:-/opt/base}"
# Never overwrite the legacy production unit or code. Cutover is separate.
ACTIVE_UNIT=/etc/systemd/system/boot-report.service
if [[ -e "$ACTIVE_UNIT" ]] && ! grep -Fxq 'ExecStart=/opt/boot-report/bin/boot-report' "$ACTIVE_UNIT"; then
  echo "BLOCKED: existing Boot service does not use the v2 entrypoint. Review and cut over explicitly." >&2
  exit 2
fi
if [[ -e "$DEST_DIR/boot-report.sh" ]]; then
  echo "BLOCKED: legacy boot-report.sh found; do not replace a running installation." >&2
  exit 2
fi
mkdir -p "$DEST_DIR" "$REPORTS_DIR" /etc/boot-report
rsync -a --exclude='.git' --exclude='dist' --exclude='config/server.env' "$SRC_DIR/" "$DEST_DIR/"
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
