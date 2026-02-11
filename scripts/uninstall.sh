\
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/boot-report"
SERVICE_NAME="boot-report.service"
USER_NAME="bootreport"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "ERROR: ejecutá como root (sudo)." >&2
  exit 1
fi

systemctl disable --now "${SERVICE_NAME}" 2>/dev/null || true
rm -f "/etc/systemd/system/${SERVICE_NAME}"
systemctl daemon-reload

rm -rf "${APP_DIR}"

if id -u "${USER_NAME}" >/dev/null 2>&1; then
  userdel "${USER_NAME}" 2>/dev/null || true
fi

echo "OK: removido."
