#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/boot-report"
SERVICE_NAME="boot-report.service"
TIMER_NAME="boot-report.timer"
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

echo "[1/7] Creando usuario dedicado (${USER_NAME}) si no existe..."
if ! id -u "${USER_NAME}" >/dev/null 2>&1; then
  useradd --system --home "${APP_DIR}" --shell /usr/sbin/nologin --user-group "${USER_NAME}"
fi

echo "[2/7] Creando directorios base..."
install -d -m 0750 -o "${USER_NAME}" -g "${GROUP_NAME}" "${APP_DIR}" "${APP_DIR}/lib" "${APP_DIR}/docs"
install -d -m 0750 -o "${USER_NAME}" -g "${GROUP_NAME}" /run/boot-report /var/lib/boot-report /var/lib/boot-report/reports

echo "[3/7] Instalando script principal..."
install -m 0750 -o "${USER_NAME}" -g "${GROUP_NAME}" ./boot-report.sh "${APP_DIR}/boot-report.sh"

echo "[4/7] Instalando librerías..."
install -m 0640 -o "${USER_NAME}" -g "${GROUP_NAME}" ./lib/*.sh "${APP_DIR}/lib/"

echo "[5/7] Instalando documentación y ejemplos..."
install -m 0644 ./README.md "${APP_DIR}/README.md"
[[ -f ./docs/Boot.pdf ]] && install -m 0644 ./docs/Boot.pdf "${APP_DIR}/docs/Boot.pdf"
[[ -f ./docs/Boot.txt ]] && install -m 0644 ./docs/Boot.txt "${APP_DIR}/docs/Boot.txt"
if [[ -f "${APP_DIR}/.env" ]]; then
  echo " - ${APP_DIR}/.env ya existe, no lo toco."
else
  install -m 0640 -o "${USER_NAME}" -g "${GROUP_NAME}" ./.env.example "${APP_DIR}/.env"
  echo " - Copié .env.example -> ${APP_DIR}/.env"
fi

echo "[6/7] Instalando units systemd..."
install -m 0644 ./systemd/${SERVICE_NAME} /etc/systemd/system/${SERVICE_NAME}
install -m 0644 ./systemd/${TIMER_NAME} /etc/systemd/system/${TIMER_NAME}

echo "[7/7] Recargando systemd y activando timer..."
systemctl daemon-reload
systemctl enable --now "${TIMER_NAME}"

echo ""
echo "OK. Próximos pasos:"
echo "  1) Editá ${APP_DIR}/.env"
echo "  2) Probá: sudo systemctl start ${SERVICE_NAME}"
echo "  3) Mirá logs: journalctl -u ${SERVICE_NAME} -b --no-pager"
echo "  4) Reportes persistidos: /var/lib/boot-report/reports"
