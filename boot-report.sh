#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/opt/boot-report/.env"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

: "${BOT_TOKEN:?Falta BOT_TOKEN en /opt/boot-report/.env}"
: "${CHAT_ID:?Falta CHAT_ID en /opt/boot-report/.env}"

SERVER_LABEL="${SERVER_LABEL:-$(hostname)}"

BOOT_ALERTS_ONLY="${BOOT_ALERTS_ONLY:-false}"
BOOT_EMOJI="${BOOT_EMOJI:-true}"

WARN_LOAD_PCT="${WARN_LOAD_PCT:-70}"
CRIT_LOAD_PCT="${CRIT_LOAD_PCT:-100}"
WARN_RAM_PCT="${WARN_RAM_PCT:-70}"
CRIT_RAM_PCT="${CRIT_RAM_PCT:-85}"
WARN_DISK_PCT="${WARN_DISK_PCT:-70}"
CRIT_DISK_PCT="${CRIT_DISK_PCT:-85}"
WARN_TEMP_C="${WARN_TEMP_C:-70}"
CRIT_TEMP_C="${CRIT_TEMP_C:-85}"

HOST="$(hostname -f 2>/dev/null || hostname)"
DATE="$(date '+%Y-%m-%d %H:%M:%S %Z')"
KERNEL="$(uname -r)"
UPTIME="$(uptime -p 2>/dev/null || true)"

# --- Dedupe DIARIO + lock ---
RUN_DATE="$(date '+%Y-%m-%d')"

RUNDIR="${XDG_RUNTIME_DIR:-/run/boot-report}"
LOCK="${RUNDIR}/lock"

STATEDIR="/var/lib/boot-report"
STAMP="${STATEDIR}/last_run_date"

mkdir -p "$RUNDIR" 2>/dev/null || true

exec 9>"$LOCK" || true
if command -v flock >/dev/null 2>&1; then
  flock -n 9 || exit 0
fi

if [[ -f "$STAMP" ]] && [[ "$(cat "$STAMP" 2>/dev/null || true)" == "$RUN_DATE" ]]; then
  logger -t boot-report "SKIP: ya se ejecutó hoy ($RUN_DATE)"
  exit 0
fi

retry_curl() {
  local tries=5 delay=1 i
  for i in $(seq 1 "$tries"); do
    if "$@"; then return 0; fi
    sleep "$delay"
    delay=$((delay * 2))
  done
  return 1
}

tg_send() {
  local text="$1"
  retry_curl curl -sS -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "parse_mode=HTML" \
    --data-urlencode "text=${text}" \
    -d "disable_web_page_preview=true" >/dev/null
}

pct_used_mem() {
  local total avail used
  total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
  avail=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
  used=$((total - avail))
  echo $(( used * 100 / total ))
}

root_disk_pct() {
  df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
}

load_pct() {
  local load cpu
  load=$(awk '{print $1}' /proc/loadavg)
  cpu=$(nproc)
  awk -v l="$load" -v c="$cpu" 'BEGIN{printf "%d", (l/c)*100}'
}

cpu_temp_c() {
  if command -v sensors >/dev/null 2>&1; then
    sensors 2>/dev/null | awk '
      /Package id 0:/ {gsub(/[+°C]/,"",$4); print int($4); exit}
      /Package id [0-9]+:/ {gsub(/[+°C]/,"",$4); print int($4); exit}
      /Core 0:/ {gsub(/[+°C]/,"",$3); print int($3); exit}
    '
    return 0
  fi
  [[ -f /sys/class/thermal/thermal_zone0/temp ]] && awk '{print int($1/1000)}' /sys/class/thermal/thermal_zone0/temp && return 0
  echo ""
}

sev() {
  local val="$1" warn="$2" crit="$3"
  if [[ "$val" -ge "$crit" ]]; then echo "CRIT"; return; fi
  if [[ "$val" -ge "$warn" ]]; then echo "WARN"; return; fi
  echo "OK"
}

icon() {
  local s="$1"
  [[ "$BOOT_EMOJI" != "true" ]] && { echo ""; return; }
  case "$s" in
    CRIT) echo "🔴" ;;
    WARN) echo "🟠" ;;
    OK)   echo "🟢" ;;
    NA)   echo "⚪" ;;
    *)    echo "⚪" ;;
  esac
}

IP_LAN="$(hostname -I 2>/dev/null | awk '{print $1}')"
IP_PUBLIC="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"
[[ -z "$IP_PUBLIC" ]] && IP_PUBLIC="$(curl -fsS --max-time 3 https://ifconfig.me/ip 2>/dev/null || true)"

LOAD_PCT="$(load_pct)"
RAM_PCT="$(pct_used_mem)"
DISK_PCT="$(root_disk_pct)"
TEMP_C="$(cpu_temp_c || true)"

LOAD_SEV="$(sev "$LOAD_PCT" "$WARN_LOAD_PCT" "$CRIT_LOAD_PCT")"
RAM_SEV="$(sev "$RAM_PCT" "$WARN_RAM_PCT" "$CRIT_RAM_PCT")"
DISK_SEV="$(sev "$DISK_PCT" "$WARN_DISK_PCT" "$CRIT_DISK_PCT")"

TEMP_SEV="NA"
if [[ -n "${TEMP_C}" ]]; then
  TEMP_SEV="$(sev "$TEMP_C" "$WARN_TEMP_C" "$CRIT_TEMP_C")"
fi

FAILED_UNITS="$(systemctl --failed --no-legend 2>/dev/null | awk '{print $1}' | paste -sd, - || true)"
[[ -z "$FAILED_UNITS" ]] && FAILED_UNITS="(none)"
UPGR="$(apt-get -s upgrade 2>/dev/null | awk '/^Inst /{c++} END{print c+0}' || echo 0)"

if [[ "$BOOT_ALERTS_ONLY" == "true" ]]; then
  if [[ "$LOAD_SEV" == "OK" && "$RAM_SEV" == "OK" && "$DISK_SEV" == "OK" && ( "$TEMP_SEV" == "OK" || "$TEMP_SEV" == "NA" ) ]]; then
    logger -t boot-report "SKIP: alerts-only, todo OK ($RUN_DATE)"
    echo "$RUN_DATE" > "$STAMP" 2>/dev/null || true
    exit 0
  fi
fi

MSG="<b>DAILY REPORT</b>
🏷️ <b>${SERVER_LABEL}</b>
🖥️ ${HOST}
🌐 LAN: <code>${IP_LAN:-?}</code>
🌍 WAN: <code>${IP_PUBLIC:-?}</code>
🧠 Kernel: <code>${KERNEL}</code>
⏱️ Uptime: ${UPTIME}
🕒 ${DATE}

<b>Métricas</b>
$(icon "$LOAD_SEV") Load: <b>${LOAD_PCT}%</b>
$(icon "$RAM_SEV") RAM : <b>${RAM_PCT}%</b>
$(icon "$DISK_SEV") Disk: <b>${DISK_PCT}%</b>
$(icon "$TEMP_SEV") Temp: <b>${TEMP_C:-n/a}°C</b>

<b>Salud</b>
🧩 Failed units: <code>${FAILED_UNITS}</code>
📦 Updates pending: <b>${UPGR}</b>
"

tg_send "$MSG"
echo "$RUN_DATE" > "$STAMP" 2>/dev/null || true
