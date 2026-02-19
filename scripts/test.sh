#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/boot-report"
ENV_FILE="${APP_DIR}/.env"
SERVICE="boot-report.service"
TIMER="boot-report.timer"
STAMP="/var/lib/boot-report/last_run_date"

SEND_TEST_MSG=1
FORCE=0
DIRECT=0
SINCE_MIN=15

usage() {
  cat <<'EOF'
Uso:
  sudo ./scripts/test.sh [opciones]

Opciones:
  --force             Fuerza envío del reporte (borra el stamp diario antes de ejecutar).
  --no-telegram-test  No envía mensaje TEST a Telegram (solo prueba el service).
  --direct            Ejecuta /opt/boot-report/boot-report.sh directo (sin systemd).
  --since-min N       Ventana de logs para journalctl (default: 15).
  -h, --help          Ayuda.

Notas:
  - El servicio tiene anti-duplicados diario: si ya corrió hoy, puede salir OK pero NO enviar nada.
    En ese caso usá --force para verificar el envío.
EOF
}

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

while [[ ${#} -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --no-telegram-test) SEND_TEST_MSG=0; shift ;;
    --direct) DIRECT=1; shift ;;
    --since-min) SINCE_MIN="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: opción desconocida: $1"; usage; exit 2 ;;
  esac
done

need_root
need_cmd bash
need_cmd curl

echo "== Boot Report: test manual =="

if [[ ! -d "${APP_DIR}" ]]; then
  echo "ERROR: no existe ${APP_DIR}. ¿Corriste ./scripts/install.sh?" >&2
  exit 1
fi

if [[ ! -x "${APP_DIR}/boot-report.sh" ]]; then
  echo "ERROR: no existe o no es ejecutable: ${APP_DIR}/boot-report.sh" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: falta ${ENV_FILE}." >&2
  exit 1
fi

set +u
source "${ENV_FILE}"
set -u

if [[ -z "${BOT_TOKEN:-}" || -z "${CHAT_ID:-}" ]]; then
  echo "ERROR: BOT_TOKEN y/o CHAT_ID faltan en ${ENV_FILE}." >&2
  exit 1
fi

echo "[Info] Script: ${APP_DIR}/boot-report.sh"
echo "[Info] Env   : ${ENV_FILE}"

echo ""
echo "-- Chequeo Telegram (getMe) --"
if curl -fsS "https://api.telegram.org/bot${BOT_TOKEN}/getMe" | grep -q '"ok"\s*:\s*true'; then
  echo "OK: el BOT_TOKEN responde (getMe)."
else
  echo "ERROR: Telegram no respondió OK a getMe. Revisá BOT_TOKEN / DNS / salida a internet." >&2
  exit 1
fi

if [[ "${SEND_TEST_MSG}" -eq 1 ]]; then
  echo ""
  echo "-- Envío de mensaje TEST --"
  TEST_TEXT="<b>BOOT REPORT TEST</b>%0AHost: <code>$(hostname)</code>%0AFecha: <code>$(date '+%Y-%m-%d %H:%M:%S %Z')</code>%0AOrigen: <code>scripts/test.sh</code>"
  if curl -fsS -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      -d "chat_id=${CHAT_ID}" \
      -d "parse_mode=HTML" \
      -d "disable_web_page_preview=true" \
      --data-urlencode "text=${TEST_TEXT}" | grep -q '"ok"\s*:\s*true'; then
    echo "OK: mensaje TEST enviado (revisá el chat)."
  else
    echo "ERROR: falló sendMessage. Revisá CHAT_ID y permisos del bot (grupo/canal)." >&2
    exit 1
  fi
fi

if [[ "${FORCE}" -eq 1 ]]; then
  echo ""
  echo "-- FORCE: limpiando anti-duplicado diario --"
  if [[ -f "${STAMP}" ]]; then
    echo "Borrando ${STAMP} (antes: $(cat "${STAMP}" 2>/dev/null || true))"
  else
    echo "No existe ${STAMP} (ok)."
  fi
  rm -f "${STAMP}" || true
fi

if [[ "${DIRECT}" -eq 1 ]]; then
  echo ""
  echo "== Ejecutando directo (sin systemd) =="
  install -d -m 0750 -o bootreport -g bootreport /run/boot-report /var/lib/boot-report 2>/dev/null || true
  export XDG_RUNTIME_DIR=/run/boot-report
  if command -v runuser >/dev/null 2>&1; then
    runuser -u bootreport -- "${APP_DIR}/boot-report.sh"
  else
    need_cmd sudo
    sudo -u bootreport "${APP_DIR}/boot-report.sh"
  fi
  echo "OK: ejecución directa finalizada."
  exit 0
fi

need_cmd systemctl
need_cmd journalctl

echo ""
echo "== Chequeo systemd =="
echo "[Timer] Estado: $(systemctl is-active "${TIMER}" 2>/dev/null || echo 'n/a') / habilitado: $(systemctl is-enabled "${TIMER}" 2>/dev/null || echo 'n/a')"
echo "[Service] Existe: $(systemctl status "${SERVICE}" >/dev/null 2>&1 && echo 'sí' || echo 'no')"

echo ""
echo "-- Próxima ejecución (timer) --"
systemctl list-timers --all | grep -E "\bboot-report\.timer\b" || true

echo ""
echo "-- Ejecutando service (manual) --"
systemctl start "${SERVICE}"

echo ""
echo "-- Resultado (systemctl show) --"
systemctl show "${SERVICE}" \
  -p ActiveState -p SubState -p Result -p ExecMainCode -p ExecMainStatus --no-pager

echo ""
echo "-- Logs recientes (${SINCE_MIN} min) --"
journalctl -u "${SERVICE}" --since "${SINCE_MIN} minutes ago" --no-pager -n 200 || true

echo ""
echo "OK: test completado."
