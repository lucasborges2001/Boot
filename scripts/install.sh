\
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/boot-report"
SERVICE_NAME="boot-report.service"
USER_NAME="bootreport"
GROUP_NAME="bootreport"

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "ERROR: ejecutá como root (sudo)." >&2
    exit 1
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: falta comando: $1" >&2
    exit 1
  }
}

need_root
need_cmd systemctl
need_cmd install

echo "[1/6] Creando usuario dedicado (${USER_NAME}) si no existe..."
if ! id -u "${USER_NAME}" >/dev/null 2>&1; then
  useradd --system --home "${APP_DIR}" --shell /usr/sbin/nologin --user-group "${USER_NAME}"
fi

echo "[2/6] Creando directorio ${APP_DIR}..."
install -d -m 0750 -o "${USER_NAME}" -g "${GROUP_NAME}" "${APP_DIR}"

echo "[3/6] Instalando script..."
install -m 0750 -o "${USER_NAME}" -g "${GROUP_NAME}" "./boot-report.sh" "${APP_DIR}/boot-report.sh"

echo "[4/6] Instalando .env..."
if [[ -f "${APP_DIR}/.env" ]]; then
  echo " - ${APP_DIR}/.env ya existe, no lo toco."
else
  install -m 0640 -o "${USER_NAME}" -g "${GROUP_NAME}" "./.env.example" "${APP_DIR}/.env"
  echo " - Copié .env.example -> ${APP_DIR}/.env (EDITALO con tu BOT_TOKEN y CHAT_ID)."
fi

echo "[5/6] Instalando units systemd..."
install -m 0644 "./systemd/boot-report.service" "/etc/systemd/system/boot-report.service"
install -m 0644 "./systemd/boot-report.timer" "/etc/systemd/system/boot-report.timer"

echo "[6/6] Activando timer diario..."
systemctl daemon-reload
systemctl enable --now boot-report.timer


echo ""
echo "OK. Próximos pasos:"
echo "  1) Editá ${APP_DIR}/.env"
echo "  2) Probá: sudo systemctl start ${SERVICE_NAME}"
echo "  3) Mirá logs: journalctl -u ${SERVICE_NAME} -b --no-pager"
