#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE_DEFAULT="/opt/boot-report/.env"
ENV_FILE_LOCAL="${APP_DIR}/.env"
if [[ -f "$ENV_FILE_DEFAULT" ]]; then
  ENV_FILE="$ENV_FILE_DEFAULT"
elif [[ -f "$ENV_FILE_LOCAL" ]]; then
  ENV_FILE="$ENV_FILE_LOCAL"
else
  ENV_FILE="$ENV_FILE_DEFAULT"
fi

set +u
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
set -u

SERVER_LABEL="${SERVER_LABEL:-$(hostname)}"
BOOT_ALERTS_ONLY="${BOOT_ALERTS_ONLY:-false}"
BOOT_EMOJI="${BOOT_EMOJI:-true}"
BOOT_NOTIFY_POLICY="${BOOT_NOTIFY_POLICY:-always}"

WARN_LOAD_PCT="${WARN_LOAD_PCT:-70}"
CRIT_LOAD_PCT="${CRIT_LOAD_PCT:-100}"
WARN_RAM_PCT="${WARN_RAM_PCT:-70}"
CRIT_RAM_PCT="${CRIT_RAM_PCT:-85}"
WARN_DISK_PCT="${WARN_DISK_PCT:-70}"
CRIT_DISK_PCT="${CRIT_DISK_PCT:-85}"
WARN_TEMP_C="${WARN_TEMP_C:-70}"
CRIT_TEMP_C="${CRIT_TEMP_C:-85}"

LIB_DIR="${APP_DIR}/lib"
source "${LIB_DIR}/runtime.sh"
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
  if [[ -z "$internal" && "${CHAT_ID:-}" =~ ^-100[0-9]+$ ]]; then
    internal="${CHAT_ID#-100}"
  fi
  : "${internal:?Falta TG_INTERNAL_CHAT_ID (o TG_BASE_MSG_URL) para botones URL.}"
  echo "https://t.me/c/${internal}"
}

_should_notify() {
  local overall="$1"
  case "$BOOT_NOTIFY_POLICY" in
    issues|warn-error)
      [[ "$overall" == "WARN" || "$overall" == "CRIT" || "$overall" == "ERROR" ]] && return 0
      return 1
      ;;
    never)
      return 1
      ;;
    always|*)
      return 0
      ;;
  esac
}

RUN_DATE="$(date '+%Y-%m-%d')"
RUNDIR="${XDG_RUNTIME_DIR:-/run/boot-report}"
LOCK="${RUNDIR}/lock"
STATEDIR="${BOOT_STATE_DIR:-/var/lib/boot-report}"
STAMP="${STATEDIR}/last_run_date"

mkdir -p "$RUNDIR" "$STATEDIR" 2>/dev/null || true
runtime_init

BOOT_PHASES=""
BOOT_OVERALL_SEV="OK"
NOTIFY_SENT="skipped"
MESSAGE_IDS=""

runtime_phase_begin precheck
: "${BOT_TOKEN:?Falta BOT_TOKEN en ${ENV_FILE}}"
: "${CHAT_ID:?Falta CHAT_ID en ${ENV_FILE}}"
for cmd in hostname date awk grep sed python3 curl; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Falta comando requerido: $cmd" >&2; exit 1; }
done
exec 9>"$LOCK" || true
if command -v flock >/dev/null 2>&1; then
  flock -n 9 || { logger -t boot-report "SKIP: ya hay otra ejecución activa"; runtime_phase_end SKIP "ya había una ejecución activa"; BOOT_PHASES="$BOOT_PHASES" runtime_write_json "$NOTIFY_SENT" "$MESSAGE_IDS"; exit 0; }
fi
runtime_phase_end OK "configuración y lock validados"

if [[ -f "$STAMP" ]] && [[ "$(cat "$STAMP" 2>/dev/null || true)" == "$RUN_DATE" ]]; then
  logger -t boot-report "SKIP: ya se ejecutó hoy ($RUN_DATE)"
  runtime_phase_begin dedupe
  runtime_phase_end SKIP "ya existía stamp diario"
  BOOT_PHASES="$BOOT_PHASES" runtime_write_json "$NOTIFY_SENT" "$MESSAGE_IDS"
  runtime_latest_link
  exit 0
fi

runtime_phase_begin collect
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
FAILED_LIST="$(printf '%s\n' "$FAILED_LIST_RAW" | _trim_lines 30)"
UPDATES_SNAPSHOT="$(sys_updates_snapshot || true)"
UPD_SEC_LIST="$(_updates_split_block SECURITY <<<"$UPDATES_SNAPSHOT" || true)"
UPD_REG_LIST="$(_updates_split_block REGULAR <<<"$UPDATES_SNAPSHOT" || true)"
UPD_HOLD_LIST="$(_updates_split_block HELD <<<"$UPDATES_SNAPSHOT" || true)"
UPD_SEC_N=$(grep -c . <<<"$UPD_SEC_LIST" 2>/dev/null || true)
UPD_REG_N=$(grep -c . <<<"$UPD_REG_LIST" 2>/dev/null || true)
UPDATES_COUNT=$((UPD_SEC_N + UPD_REG_N))
LOAD_TREND="$(sys_metric_trend "$LOAD_PCT" load 2>/dev/null || echo '→ 0')"
RAM_TREND="$(sys_metric_trend "$RAM_PCT" ram 2>/dev/null || echo '→ 0')"
DISK_TREND="$(sys_metric_trend "$DISK_PCT" disk 2>/dev/null || echo '→ 0')"
SERVICE_CHANGES="$(sys_service_changes 2>/dev/null || true)"
runtime_phase_end OK "señales del host recolectadas"

runtime_phase_begin evaluate
LOAD_SEV="$(_sev "$LOAD_PCT" "$WARN_LOAD_PCT" "$CRIT_LOAD_PCT")"
RAM_SEV="$(_sev "$RAM_PCT" "$WARN_RAM_PCT" "$CRIT_RAM_PCT")"
DISK_SEV="$(_sev "$DISK_PCT" "$WARN_DISK_PCT" "$CRIT_DISK_PCT")"
TEMP_SEV="NA"
if [[ -n "$TEMP_CPU_MAX_C" ]]; then
  TEMP_SEV="$(_sev "$TEMP_CPU_MAX_C" "$WARN_TEMP_C" "$CRIT_TEMP_C")"
fi
NEED_NETWORK="false"
[[ -z "$IP_WAN" ]] && NEED_NETWORK="true"
NEED_TOP="false"
[[ "$LOAD_SEV" != "OK" || "$RAM_SEV" != "OK" ]] && NEED_TOP="true"
BOOT_SMART_CHECK="${BOOT_SMART_CHECK:-weekly}"
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
        (( now_s - last_s >= 7*24*3600 )) && SMART_SHOULD_RUN="true"
      fi
      ;;
  esac
fi
if [[ "$SMART_SHOULD_RUN" == "true" ]]; then
  SMART_STATUS="$(sys_smartctl_status 2>/dev/null || echo UNKNOWN)"
  date '+%Y-%m-%d' > "${STATEDIR}/last_smart_date" 2>/dev/null || true
fi
ALERTS_TEXT=""
[[ "$LOAD_SEV" == "CRIT" ]] && ALERTS_TEXT+="• Carga crítica: ${LOAD_PCT}% (límite ${CRIT_LOAD_PCT}%)"$'\n'
[[ "$RAM_SEV" == "CRIT" ]] && ALERTS_TEXT+="• Memoria crítica: ${RAM_PCT}% (límite ${CRIT_RAM_PCT}%)"$'\n'
[[ "$DISK_SEV" == "CRIT" ]] && ALERTS_TEXT+="• Disco crítico: ${DISK_PCT}% (límite ${CRIT_DISK_PCT}%)"$'\n'
[[ "$TEMP_SEV" == "CRIT" ]] && ALERTS_TEXT+="• Temperatura crítica: ${TEMP_CPU_MAX_C}°C (límite ${CRIT_TEMP_C}°C)"$'\n'
if [[ "$FAILED_COUNT" -gt 0 ]]; then
  top_failed="$(printf '%s\n' "$FAILED_LIST" | head -3 | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  ALERTS_TEXT+="• Servicios fallidos: ${FAILED_COUNT} (${top_failed})"$'\n'
fi
[[ "$NEED_NETWORK" == "true" ]] && ALERTS_TEXT+="• WAN: no se pudo obtener IP pública"$'\n'
[[ "$SMART_STATUS" == "FAIL" ]] && ALERTS_TEXT+="• Disco: SMART FAIL"$'\n'
SIGNAL_OVERALL="OK"
for sev in "$LOAD_SEV" "$RAM_SEV" "$DISK_SEV" "$TEMP_SEV"; do
  [[ "$sev" == "WARN" ]] && SIGNAL_OVERALL="$(runtime_max_sev "$SIGNAL_OVERALL" WARN)"
  [[ "$sev" == "CRIT" ]] && SIGNAL_OVERALL="$(runtime_max_sev "$SIGNAL_OVERALL" CRIT)"
done
[[ "$FAILED_COUNT" -gt 0 ]] && SIGNAL_OVERALL="$(runtime_max_sev "$SIGNAL_OVERALL" CRIT)"
[[ "$UPD_SEC_N" -gt 0 ]] && SIGNAL_OVERALL="$(runtime_max_sev "$SIGNAL_OVERALL" WARN)"
runtime_phase_end "$SIGNAL_OVERALL" "severidades calculadas"

if [[ "$BOOT_ALERTS_ONLY" == "true" ]]; then
  if [[ "$LOAD_SEV" == "OK" && "$RAM_SEV" == "OK" && "$DISK_SEV" == "OK" && ( "$TEMP_SEV" == "OK" || "$TEMP_SEV" == "NA" ) && "$FAILED_COUNT" -eq 0 && "$UPD_SEC_N" -eq 0 ]]; then
    logger -t boot-report "SKIP: alerts-only, todo OK ($RUN_DATE)"
    echo "$RUN_DATE" > "$STAMP" 2>/dev/null || true
    runtime_phase_begin notify
    runtime_phase_end SKIP "alerts-only activo y sin incidencias"
    BOOT_PHASES="$BOOT_PHASES" runtime_write_json "$NOTIFY_SENT" "$MESSAGE_IDS"
    runtime_latest_link
    exit 0
  fi
fi

runtime_phase_begin render
SECURITY_BANNER="$(render_security_banner "$UPD_SEC_N")"
CRITICAL_BANNER=""
[[ -n "$ALERTS_TEXT" ]] && CRITICAL_BANNER="$(render_critical_banner "$ALERTS_TEXT")"
SUMMARY_TXT="$(render_summary \
  "$SERVER_LABEL" "$HOST" "$IP_LAN" "$IP_WAN" "$KERNEL" "$UPTIME" "$DATE" \
  "$LOAD_PCT" "$LOAD_SEV" "$RAM_PCT" "$RAM_SEV" "$DISK_PCT" "$DISK_SEV" \
  "$TEMP_CPU_MAX_C" "$TEMP_SEV" "$UPDATES_COUNT" "$UPD_SEC_N" "$FAILED_COUNT" \
  "$WARN_LOAD_PCT" "$CRIT_LOAD_PCT" "$WARN_RAM_PCT" "$CRIT_RAM_PCT" \
  "$WARN_DISK_PCT" "$CRIT_DISK_PCT" "$WARN_TEMP_C" "$CRIT_TEMP_C" \
  "$LOAD_TREND" "$RAM_TREND" "$DISK_TREND")"
NETWORK_TXT=""
[[ "$NEED_NETWORK" == "true" ]] && NETWORK_TXT="$(sys_network_info 2>/dev/null || true)" && NETWORK_TXT="$(render_network_info "$NETWORK_TXT" || true)"
TOP_PROCESSES_TXT=""
if [[ "$NEED_TOP" == "true" ]]; then
  TOP_CPU="$(sys_top_processes cpu 5 2>/dev/null || true)"
  TOP_RAM="$(sys_top_processes mem 5 2>/dev/null || true)"
  TOP_PROCESSES_TXT="$(render_top_processes "$TOP_CPU" "$TOP_RAM" || true)"
fi
DISK_HEALTH_TXT="$(render_disk_health "$SMART_STATUS" || true)"
TEMP_GROUPS_TRIM="$(printf '%s\n' "$TEMP_GROUPS" | _trim_lines 90)"
TEMPS_TXT="$(render_temps_detail "$TEMP_CPU_MAX_C" "$TEMP_SEV" "$TEMP_GROUPS_TRIM")"
UPDATES_TXT="$(render_updates_detail "$UPD_SEC_LIST" "$UPD_REG_LIST" "$UPD_HOLD_LIST")"
SERVICES_TXT="$(render_services_detail "$FAILED_LIST" "$SERVICE_CHANGES")"
HOWTO_TXT="$(render_update_howto)"
runtime_write_summary "$SUMMARY_TXT"
runtime_phase_end OK "mensajes renderizados y resumen persistido"

runtime_phase_begin notify
if _should_notify "$SIGNAL_OVERALL"; then
  TG_BASE_MSG_URL="$(_calc_tg_base_url)"
  security_id=""
  critical_id=""
  if [[ -n "$SECURITY_BANNER" ]]; then
    security_id="$(tg_send_message "$SECURITY_BANNER")"
  fi
  if [[ -n "$CRITICAL_BANNER" ]]; then
    critical_id="$(tg_send_message "$CRITICAL_BANNER")"
  fi
  summary_id="$(tg_send_message "$SUMMARY_TXT")"
  temps_id="$(tg_send_message "$TEMPS_TXT" "$summary_id")"
  updates_id="$(tg_send_message "$UPDATES_TXT" "$summary_id")"
  services_id="$(tg_send_message "$SERVICES_TXT" "$summary_id")"
  howto_id="$(tg_send_message "$HOWTO_TXT" "$summary_id")"
  network_id=""
  [[ -n "$NETWORK_TXT" ]] && network_id="$(tg_send_message "$NETWORK_TXT" "$summary_id")"
  top_processes_id=""
  [[ -n "$TOP_PROCESSES_TXT" ]] && top_processes_id="$(tg_send_message "$TOP_PROCESSES_TXT" "$summary_id")"
  disk_health_id=""
  [[ -n "$DISK_HEALTH_TXT" ]] && disk_health_id="$(tg_send_message "$DISK_HEALTH_TXT" "$summary_id")"
  temps_url="${TG_BASE_MSG_URL}/${temps_id}"
  updates_url="${TG_BASE_MSG_URL}/${updates_id}"
  services_url="${TG_BASE_MSG_URL}/${services_id}"
  howto_url="${TG_BASE_MSG_URL}/${howto_id}"
  reply_markup="$(render_buttons_json "$temps_url" "$updates_url" "$services_url" "$howto_url")"
  tg_edit_reply_markup "$summary_id" "$reply_markup"
  NOTIFY_SENT="sent"
  MESSAGE_IDS="security_id=${security_id}
critical_id=${critical_id}
summary_id=${summary_id}
network_id=${network_id}
top_processes_id=${top_processes_id}
disk_health_id=${disk_health_id}
temps_id=${temps_id}
updates_id=${updates_id}
services_id=${services_id}
howto_id=${howto_id}"
  runtime_phase_end OK "reporte enviado a telegram"
else
  NOTIFY_SENT="skipped"
  runtime_phase_end SKIP "política de notificación no requiere envío"
fi

runtime_phase_begin persist
printf '%s' "$RUN_DATE" > "$STAMP" 2>/dev/null || true
BOOT_PHASES="$BOOT_PHASES" runtime_write_json "$NOTIFY_SENT" "$MESSAGE_IDS"
runtime_latest_link
runtime_cleanup_reports
runtime_phase_end OK "estado y reportes persistidos"
BOOT_PHASES="$BOOT_PHASES" runtime_write_json "$NOTIFY_SENT" "$MESSAGE_IDS"

printf '%s\n' "$MESSAGE_IDS"
