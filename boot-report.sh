\
#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/opt/boot-report/.env"

log_ok()   { echo "BOOT_REPORT_OK $*"; }
log_fail() { echo "BOOT_REPORT_FAIL $*"; }
log_skip() { echo "BOOT_REPORT_SKIP $*"; }

# --------------------------- Utils ----------------------------------------

retry_backoff() {
  local tries="${1:-6}"; shift
  local i=1 delay=1
  while (( i <= tries )); do
    if "$@"; then return 0; fi
    sleep "$delay"
    delay=$((delay*2)); (( delay > 24 )) && delay=24
    i=$((i+1))
  done
  return 1
}

curl_quiet() { curl -fsS --max-time 7 "$@"; }

escape_html() {
  # Escapa &, <, > para Telegram parse_mode=HTML
  sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

emoji() {
  [[ "${BOOT_EMOJI:-true}" == "true" ]] || { echo ""; return; }
  echo -n "$1"
}

badge_pct() {
  # echo: "OK" | "WARN" | "CRIT" (con emoji opcional)
  local val="$1" warn="$2" crit="$3"
  if (( val < warn )); then echo "$(emoji "🟢 ")OK"
  elif (( val < crit )); then echo "$(emoji "🟠 ")WARN"
  else echo "$(emoji "🔴 ")CRIT"
  fi
}

badge_load() {
  # compara load por core (float) vs warn/crit (float)
  local val="$1" warn="$2" crit="$3"
  awk -v v="$val" -v w="$warn" -v c="$crit" 'BEGIN{
    if (v < w)      print "OK";
    else if (v < c) print "WARN";
    else            print "CRIT";
  }' | {
    read -r b
    case "$b" in
      OK)   echo "$(emoji "🟢 ")OK" ;;
      WARN) echo "$(emoji "🟠 ")WARN" ;;
      *)    echo "$(emoji "🔴 ")CRIT" ;;
    esac
  }
}

net_ready() {
  # Ruta + DNS: evita "network-online" falso.
  ip route get "${NET_CHECK_IP:-1.1.1.1}" >/dev/null 2>&1 || return 1
  getent hosts "${NET_CHECK_DNS:-api.telegram.org}" >/dev/null 2>&1 || return 1
}

get_ip_pub() {
  local ip=""
  ip="$(curl_quiet https://api.ipify.org || true)"
  [[ -z "$ip" ]] && ip="$(curl_quiet ifconfig.me || true)"
  [[ -n "$ip" ]] || return 1
  echo "$ip"
}

send_telegram() {
  # Requiere: BOT_TOKEN, CHAT_ID, MSG (HTML)
  local resp
  resp="$(
    curl -fsS --max-time 12 -X POST \
      "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      -d chat_id="${CHAT_ID}" \
      -d parse_mode="HTML" \
      -d disable_web_page_preview="true" \
      --data-urlencode text="${MSG}"
  )" || return 1
  # Telegram puede responder 200 pero ok=false; validamos.
  grep -q '"ok"[[:space:]]*:[[:space:]]*true' <<<"$resp"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log_fail "missing_cmd=$1"
    exit 1
  }
}

# --------------------------- Load env -------------------------------------

if [[ ! -f "$ENV_FILE" ]]; then
  log_fail "missing_env_file=$ENV_FILE"
  exit 1
fi

# shellcheck disable=SC1090
set -a
source "$ENV_FILE"
set +a

: "${BOT_TOKEN:?missing BOT_TOKEN in $ENV_FILE}"
: "${CHAT_ID:?missing CHAT_ID in $ENV_FILE}"
SERVER_LABEL="${SERVER_LABEL:-$(hostname)}"

# ------------------------ Anti-duplicados ---------------------------------

RUNDIR="${BOOT_REPORT_RUNDIR:-/run/boot-report}"
LOCK_TTL_SEC="${LOCK_TTL_SEC:-900}"

# Fallback si no existe
if [[ ! -d "$RUNDIR" ]]; then
  RUNDIR="/tmp/boot-report"
  mkdir -p "$RUNDIR"
fi

LOCK_FILE="${RUNDIR}/boot-report.lock"
STAMP_FILE="${RUNDIR}/boot-report.stamp"

BOOT_ID="$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo "unknown")"
NOW_EPOCH="$(date +%s)"

# lock no bloqueante
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log_skip "lock_busy"
  exit 0
fi

# stamp: si ya enviamos para este boot dentro de TTL, saltamos
if [[ -f "$STAMP_FILE" ]]; then
  read -r last_epoch last_boot_id <"$STAMP_FILE" || true
  last_epoch="${last_epoch:-0}"
  last_boot_id="${last_boot_id:-}"
  if [[ "$last_boot_id" == "$BOOT_ID" ]] && (( NOW_EPOCH - last_epoch < LOCK_TTL_SEC )); then
    log_skip "duplicate_within_ttl boot_id=$BOOT_ID age=$((NOW_EPOCH-last_epoch))"
    exit 0
  fi
fi

# --------------------------- Recoleccion ----------------------------------

require_cmd awk
require_cmd df
require_cmd free
require_cmd hostname
require_cmd ip
require_cmd curl

HOST="$(hostname -f 2>/dev/null || hostname)"
OS_NAME="$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-unknown}")"
KERNEL="$(uname -r)"
BOOT_TIME="$(uptime -s 2>/dev/null || true)"
UPTIME_H="$(uptime -p 2>/dev/null || true)"

CORES="$(nproc 2>/dev/null || echo 1)"
LOAD1="$(awk '{print $1}' /proc/loadavg)"
LOAD_PER_CORE="$(awk -v l="$LOAD1" -v c="$CORES" 'BEGIN{printf "%.2f", (c>0?l/c:l)}')"

MEM_PCT="$(
  free -m | awk 'NR==2{ if ($2==0) {print 0} else { printf "%d", ($3*100)/$2 } }'
)"
DISK_PCT="$(df -P / | awk 'NR==2{gsub(/%/,"",$5); print $5}')"

TEMP_C=""
if command -v sensors >/dev/null 2>&1; then
  # Mejor esfuerzo: primera temp positiva encontrada
  TEMP_C="$(sensors 2>/dev/null | awk '/\+?[0-9]+\.[0-9]+°C/ {gsub(/[+°C]/,"",$2); print int($2); exit}')"
fi

UPDATES=""
if command -v apt >/dev/null 2>&1; then
  # cuenta upgradeables (best effort; sin root)
  UPDATES="$(LC_ALL=C apt list --upgradeable 2>/dev/null | awk 'NR>1{c++} END{print c+0}')"
fi

NEED_REBOOT="no"
[[ -f /var/run/reboot-required ]] && NEED_REBOOT="yes"

PUB_IP="$(get_ip_pub 2>/dev/null || echo "-")"
LAN_IP="$(ip -o -4 addr show scope global 2>/dev/null | awk '{print $4}' | head -n1 || true)"
GATEWAY="$(ip route show default 2>/dev/null | awk '{print $3; exit}' || true)"

DISK_BADGE="$(badge_pct "$DISK_PCT" "${WARN_DISK_PCT:-85}" "${CRIT_DISK_PCT:-95}")"
MEM_BADGE="$(badge_pct "$MEM_PCT" "${WARN_MEM_PCT:-85}" "${CRIT_MEM_PCT:-95}")"
LOAD_BADGE="$(badge_load "$LOAD_PER_CORE" "${WARN_LOAD_PER_CORE:-1.50}" "${CRIT_LOAD_PER_CORE:-2.50}")"
TEMP_BADGE=""
if [[ -n "$TEMP_C" ]]; then
  TEMP_BADGE="$(badge_pct "$TEMP_C" "${WARN_TEMP_C:-70}" "${CRIT_TEMP_C:-85}")"
fi

HAS_ALERTS="false"
for b in "$DISK_BADGE" "$MEM_BADGE" "$LOAD_BADGE" "$TEMP_BADGE"; do
  [[ "$b" == *"WARN"* || "$b" == *"CRIT"* ]] && HAS_ALERTS="true"
done
[[ "$NEED_REBOOT" == "yes" ]] && HAS_ALERTS="true"

if [[ "${BOOT_ALERTS_ONLY:-false}" == "true" && "$HAS_ALERTS" != "true" ]]; then
  log_skip "alerts_only_no_alerts"
  exit 0
fi

# systemd-analyze (best effort)
SA_TIME="$(systemd-analyze time 2>/dev/null | head -n1 || true)"

# --------------------------- Mensaje --------------------------------------

MSG="$(
  {
    echo "<b>Boot Report — ${SERVER_LABEL}</b>"
    echo "<pre>host:   ${HOST}</pre>"
    echo "<pre>os:     ${OS_NAME}</pre>"
    echo "<pre>kernel: ${KERNEL}</pre>"
    [[ -n "$BOOT_TIME" ]] && echo "<pre>boot:   ${BOOT_TIME}</pre>"
    [[ -n "$UPTIME_H" ]] && echo "<pre>uptime: ${UPTIME_H}</pre>"
    [[ -n "$SA_TIME" ]] && echo "<pre>analyze: ${SA_TIME}</pre>"
    echo ""
    echo "<b>Salud</b>"
    echo "<pre>disk / : ${DISK_PCT}%  (${DISK_BADGE})</pre>"
    echo "<pre>mem     : ${MEM_PCT}%  (${MEM_BADGE})</pre>"
    echo "<pre>load/core: ${LOAD_PER_CORE}  (${LOAD_BADGE})</pre>"
    [[ -n "$TEMP_C" ]] && echo "<pre>temp    : ${TEMP_C}C  (${TEMP_BADGE})</pre>"
    echo ""
    echo "<b>Operacion</b>"
    [[ -n "$UPDATES" ]] && echo "<pre>updates : ${UPDATES}</pre>"
    echo "<pre>reboot? : ${NEED_REBOOT}</pre>"
    echo ""
    echo "<b>Red</b>"
    [[ -n "$LAN_IP" ]] && echo "<pre>lan     : ${LAN_IP}</pre>"
    [[ -n "$GATEWAY" ]] && echo "<pre>gw      : ${GATEWAY}</pre>"
    echo "<pre>public  : ${PUB_IP}</pre>"
    echo ""
    echo "<pre>boot_id : ${BOOT_ID}</pre>"
  } | escape_html
)"

# --------------------------- Envio ----------------------------------------

# Espera a que haya conectividad minima
if ! retry_backoff 10 net_ready; then
  log_fail "net_not_ready"
  exit 1
fi

if retry_backoff 6 send_telegram; then
  printf '%s %s\n' "$NOW_EPOCH" "$BOOT_ID" >"$STAMP_FILE"
  chmod 600 "$STAMP_FILE" 2>/dev/null || true
  log_ok "sent boot_id=$BOOT_ID alerts=$HAS_ALERTS"
  exit 0
else
  log_fail "telegram_send_failed"
  exit 1
fi
