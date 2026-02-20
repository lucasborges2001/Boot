#!/usr/bin/env bash
set -euo pipefail

# boot-report.sh (orquestador)
# - lib/system.sh  : recolecta datos
# - lib/render.sh  : arma mensajes (HTML)
# - lib/telegram.sh: envía / edita botones

ENV_FILE="/opt/boot-report/.env"
set +u
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
set -u

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

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${APP_DIR}/lib"

# Importante: telegram.sh define tg_escape_html usado por render.sh
source "${LIB_DIR}/telegram.sh"
source "${LIB_DIR}/system.sh"
source "${LIB_DIR}/render.sh"

_sev() {
  local val="$1" warn="$2" crit="$3"
  if [[ "$val" -ge "$crit" ]]; then echo "CRIT"; return; fi
  if [[ "$val" -ge "$warn" ]]; then echo "WARN"; return; fi
  echo "OK"
}

_trim_lines() {
  local max_lines="$1"
  awk -v n="$max_lines" 'NR<=n{print}'
}

_updates_split_block() {
  # args: block_name (SECURITY|REGULAR|HELD)
  local name="$1"
  awk -v n="$name" '
    $0=="--"n"--" {p=1; next}
    /^--(SECURITY|REGULAR|HELD)--$/ {if(p) exit; next}
    p{print}
  '
}

_calc_tg_base_url() {
  if [[ -n "${TG_BASE_MSG_URL:-}" ]]; then
    echo "${TG_BASE_MSG_URL%/}"
    return 0
  fi

  local internal="${TG_INTERNAL_CHAT_ID:-}"

  # Fallback (solo si te olvidaste TG_INTERNAL_CHAT_ID y el CHAT_ID tiene -100...)
  # Nota: NO es 100% garantizado, pero suele coincidir.
  if [[ -z "$internal" && "${CHAT_ID:-}" =~ ^-100[0-9]+$ ]]; then
    internal="${CHAT_ID#-100}"
  fi

  : "${internal:?Falta TG_INTERNAL_CHAT_ID (o TG_BASE_MSG_URL) para botones URL.}"
  echo "https://t.me/c/${internal}"
}

# --- Dedupe diario + lock ---
RUN_DATE="$(date '+%Y-%m-%d')"

RUNDIR="${XDG_RUNTIME_DIR:-/run/boot-report}"
LOCK="${RUNDIR}/lock"

STATEDIR="/var/lib/boot-report"
STAMP="${STATEDIR}/last_run_date"

mkdir -p "$RUNDIR" "$STATEDIR" 2>/dev/null || true

exec 9>"$LOCK" || true
if command -v flock >/dev/null 2>&1; then
  flock -n 9 || exit 0
fi

if [[ -f "$STAMP" ]] && [[ "$(cat "$STAMP" 2>/dev/null || true)" == "$RUN_DATE" ]]; then
  logger -t boot-report "SKIP: ya se ejecutó hoy ($RUN_DATE)"
  exit 0
fi

# --- Recolección (system.sh) ---
HOST="$(sys_hostname)"
DATE="$(sys_now)"
KERNEL="$(sys_kernel)"
UPTIME="$(sys_uptime_pretty)"
IP_LAN="$(sys_ip_lan)"
IP_WAN="$(sys_ip_wan)"

LOAD_PCT="$(sys_load_pct)"
RAM_PCT="$(sys_pct_used_mem)"
DISK_PCT="$(sys_root_disk_pct)"

TEMP_CPU_MAX_C="$(sys_cpu_pkg_max_c || true)"
TEMP_GROUPS="$(sys_temp_groups_html || true)"

FAILED_LIST_RAW="$(sys_failed_units_list || true)"
FAILED_COUNT=$(grep -c . <<<"$FAILED_LIST_RAW" 2>/dev/null || true)
# límite defensivo por tamaño
FAILED_LIST="$(printf '%s\n' "$FAILED_LIST_RAW" | _trim_lines 30)"

UPDATES_SNAPSHOT="$(sys_updates_snapshot || true)"
UPD_SEC_LIST="$(_updates_split_block SECURITY <<<"$UPDATES_SNAPSHOT" || true)"
UPD_REG_LIST="$(_updates_split_block REGULAR <<<"$UPDATES_SNAPSHOT" || true)"
UPD_HOLD_LIST="$(_updates_split_block HELD <<<"$UPDATES_SNAPSHOT" || true)"

UPD_SEC_N=$(grep -c . <<<"$UPD_SEC_LIST" 2>/dev/null || true)
UPD_REG_N=$(grep -c . <<<"$UPD_REG_LIST" 2>/dev/null || true)
UPDATES_COUNT=$((UPD_SEC_N + UPD_REG_N))

# --- Tendencias ---
LOAD_TREND="$(sys_metric_trend "$LOAD_PCT" "load" 2>/dev/null || echo "→ 0")"
RAM_TREND="$(sys_metric_trend "$RAM_PCT" "ram" 2>/dev/null || echo "→ 0")"
DISK_TREND="$(sys_metric_trend "$DISK_PCT" "disk" 2>/dev/null || echo "→ 0")"

# --- Severidad ---
LOAD_SEV="$(_sev "$LOAD_PCT" "$WARN_LOAD_PCT" "$CRIT_LOAD_PCT")"
RAM_SEV="$(_sev "$RAM_PCT" "$WARN_RAM_PCT" "$CRIT_RAM_PCT")"
DISK_SEV="$(_sev "$DISK_PCT" "$WARN_DISK_PCT" "$CRIT_DISK_PCT")"

TEMP_SEV="NA"
if [[ -n "${TEMP_CPU_MAX_C}" ]]; then
  TEMP_SEV="$(_sev "$TEMP_CPU_MAX_C" "$WARN_TEMP_C" "$CRIT_TEMP_C")"
fi

# --- Recolección (condicional / bajo impacto) ---
SERVICE_CHANGES="$(sys_service_changes 2>/dev/null || true)"

NEED_NETWORK="false"
[[ -z "$IP_WAN" ]] && NEED_NETWORK="true"

NEED_TOP="false"
[[ "$LOAD_SEV" != "OK" || "$RAM_SEV" != "OK" ]] && NEED_TOP="true"

# SMART: por defecto semanal (evita cargar el server innecesariamente)
BOOT_SMART_CHECK="${BOOT_SMART_CHECK:-weekly}" # off|daily|weekly|onwarn
SMART_STATUS="UNKNOWN"
SMART_SHOULD_RUN="false"
if command -v smartctl >/dev/null 2>&1 && [[ "$BOOT_SMART_CHECK" != "off" ]]; then
  case "$BOOT_SMART_CHECK" in
    daily) SMART_SHOULD_RUN="true" ;;
    onwarn) [[ "$DISK_SEV" != "OK" ]] && SMART_SHOULD_RUN="true" ;;
    weekly|*)
      smart_stamp="${STATEDIR}/last_smart_date"
      if [[ ! -f "$smart_stamp" ]]; then
        SMART_SHOULD_RUN="true"
      else
        last="$(cat "$smart_stamp" 2>/dev/null || true)"
        now_s="$(date +%s)"
        last_s="$(date -d "$last" +%s 2>/dev/null || echo 0)"
        # 7 días
        (( now_s - last_s >= 7*24*3600 )) && SMART_SHOULD_RUN="true"
      fi
      ;;
  esac
fi

if [[ "$SMART_SHOULD_RUN" == "true" ]]; then
  SMART_STATUS="$(sys_smartctl_status 2>/dev/null || echo UNKNOWN)"
  date '+%Y-%m-%d' > "${STATEDIR}/last_smart_date" 2>/dev/null || true
fi

# --- Alertas (solo si hay algo realmente accionable) ---
ALERTS_TEXT=""

if [[ "$LOAD_SEV" == "CRIT" ]]; then
  ALERTS_TEXT+="• Carga crítica: ${LOAD_PCT}% (límite ${CRIT_LOAD_PCT}%)"$'\n'
fi
if [[ "$RAM_SEV" == "CRIT" ]]; then
  ALERTS_TEXT+="• Memoria crítica: ${RAM_PCT}% (límite ${CRIT_RAM_PCT}%)"$'\n'
fi
if [[ "$DISK_SEV" == "CRIT" ]]; then
  ALERTS_TEXT+="• Disco crítico: ${DISK_PCT}% (límite ${CRIT_DISK_PCT}%)"$'\n'
fi
if [[ "$TEMP_SEV" == "CRIT" ]]; then
  ALERTS_TEXT+="• Temperatura crítica: ${TEMP_CPU_MAX_C}°C (límite ${CRIT_TEMP_C}°C)"$'\n'
fi
if [[ "$FAILED_COUNT" -gt 0 ]]; then
  top_failed="$(printf '%s\n' "$FAILED_LIST" | head -3 | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  ALERTS_TEXT+="• Servicios fallidos: ${FAILED_COUNT} (${top_failed})"$'\n'
fi
if [[ "$NEED_NETWORK" == "true" ]]; then
  ALERTS_TEXT+="• WAN: no se pudo obtener IP pública"$'\n'
fi
if [[ "$SMART_STATUS" == "FAIL" ]]; then
  ALERTS_TEXT+="• Disco: SMART FAIL"$'\n'
fi

# alerts-only: métricas + failed (NO updates)
if [[ "$BOOT_ALERTS_ONLY" == "true" ]]; then
  if [[ "$LOAD_SEV" == "OK" && "$RAM_SEV" == "OK" && "$DISK_SEV" == "OK" && ( "$TEMP_SEV" == "OK" || "$TEMP_SEV" == "NA" ) && "$FAILED_COUNT" -eq 0 && "$UPD_SEC_N" -eq 0 ]]; then
    logger -t boot-report "SKIP: alerts-only, todo OK ($RUN_DATE)"
    echo "$RUN_DATE" > "$STAMP" 2>/dev/null || true
    exit 0
  fi
fi

# --- Render (render.sh) ---
SECURITY_BANNER="$(render_security_banner "$UPD_SEC_N")"

CRITICAL_BANNER=""
if [[ -n "$ALERTS_TEXT" ]]; then
  CRITICAL_BANNER="$(render_critical_banner "$ALERTS_TEXT")"
fi

SUMMARY_TXT="$(render_summary \
  "$SERVER_LABEL" "$HOST" "$IP_LAN" "$IP_WAN" "$KERNEL" "$UPTIME" "$DATE" \
  "$LOAD_PCT" "$LOAD_SEV" "$RAM_PCT" "$RAM_SEV" "$DISK_PCT" "$DISK_SEV" \
  "$TEMP_CPU_MAX_C" "$TEMP_SEV" "$UPDATES_COUNT" "$UPD_SEC_N" "$FAILED_COUNT" \
  "$WARN_LOAD_PCT" "$CRIT_LOAD_PCT" "$WARN_RAM_PCT" "$CRIT_RAM_PCT" \
  "$WARN_DISK_PCT" "$CRIT_DISK_PCT" "$WARN_TEMP_C" "$CRIT_TEMP_C" \
  "$LOAD_TREND" "$RAM_TREND" "$DISK_TREND"
)"

NETWORK_TXT=""
if [[ "$NEED_NETWORK" == "true" ]]; then
  NETWORK_INFO="$(sys_network_info 2>/dev/null || true)"
  NETWORK_TXT="$(render_network_info "$NETWORK_INFO" || true)"
fi

TOP_PROCESSES_TXT=""
if [[ "$NEED_TOP" == "true" ]]; then
  TOP_CPU="$(sys_top_processes cpu 5 2>/dev/null || true)"
  TOP_RAM="$(sys_top_processes mem 5 2>/dev/null || true)"
  TOP_PROCESSES_TXT="$(render_top_processes "$TOP_CPU" "$TOP_RAM" || true)"
fi

DISK_HEALTH_TXT="$(render_disk_health "$SMART_STATUS" || true)"

# límite defensivo por tamaño
TEMP_GROUPS_TRIM="$(printf '%s\n' "$TEMP_GROUPS" | _trim_lines 90)"
TEMPS_TXT="$(render_temps_detail "$TEMP_CPU_MAX_C" "$TEMP_SEV" "$TEMP_GROUPS_TRIM")"

UPDATES_TXT="$(render_updates_detail "$UPD_SEC_LIST" "$UPD_REG_LIST" "$UPD_HOLD_LIST")"
SERVICES_TXT="$(render_services_detail "$FAILED_LIST" "$SERVICE_CHANGES")"
HOWTO_TXT="$(render_update_howto)"

# --- Envío (telegram.sh) ---
TG_BASE_MSG_URL="$(_calc_tg_base_url)"

# Mensaje principal: primero el banner de seguridad si existe
if [[ -n "$SECURITY_BANNER" ]]; then
  security_id="$(tg_send_message "$SECURITY_BANNER")"
else
  security_id=""
fi

# Segundo: banner de alertas críticas si existen
critical_id=""
if [[ -n "$CRITICAL_BANNER" ]]; then
  critical_id="$(tg_send_message "$CRITICAL_BANNER")"
fi

# Tercero: resumen principal (siempre)
summary_id="$(tg_send_message "$SUMMARY_TXT")"

# Detalles contextuales
temps_id="$(tg_send_message "$TEMPS_TXT" "$summary_id")"
updates_id="$(tg_send_message "$UPDATES_TXT" "$summary_id")"
services_id="$(tg_send_message "$SERVICES_TXT" "$summary_id")"
howto_id="$(tg_send_message "$HOWTO_TXT" "$summary_id")"

# Extras (solo cuando hay señal)
network_id=""
[[ -n "$NETWORK_TXT" ]] && network_id="$(tg_send_message "$NETWORK_TXT" "$summary_id")"

top_processes_id=""
[[ -n "$TOP_PROCESSES_TXT" ]] && top_processes_id="$(tg_send_message "$TOP_PROCESSES_TXT" "$summary_id")"

disk_health_id=""
[[ -n "$DISK_HEALTH_TXT" ]] && disk_health_id="$(tg_send_message "$DISK_HEALTH_TXT" "$summary_id")"

# --- Botones URL en el resumen ---
temps_url="${TG_BASE_MSG_URL}/${temps_id}"
updates_url="${TG_BASE_MSG_URL}/${updates_id}"
services_url="${TG_BASE_MSG_URL}/${services_id}"
howto_url="${TG_BASE_MSG_URL}/${howto_id}"

reply_markup="$(render_buttons_json "$temps_url" "$updates_url" "$services_url" "$howto_url")"
tg_edit_reply_markup "$summary_id" "$reply_markup"

# --- Stamp (si todo OK) ---
echo "$RUN_DATE" > "$STAMP" 2>/dev/null || true

# Debug útil para scripts/test.sh y journalctl
echo "security_id=${security_id}"
echo "critical_id=${critical_id}"
echo "summary_id=${summary_id}"
echo "network_id=${network_id}"
echo "top_processes_id=${top_processes_id}"
echo "disk_health_id=${disk_health_id}"
echo "temps_id=${temps_id} url=${temps_url}"
echo "updates_id=${updates_id} url=${updates_url}"
echo "services_id=${services_id} url=${services_url}"
echo "howto_id=${howto_id} url=${howto_url}"