#!/usr/bin/env bash
# Boot-specific metric collection. Generic env/json/log/time helpers come from Base.

if [[ -n "${BOOT_COLLECT_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_COLLECT_SH_INCLUDED=1

boot_collect_hostname() {
  hostname -f 2>/dev/null || hostname 2>/dev/null || printf 'unknown\n'
}

boot_collect_kernel() {
  uname -r 2>/dev/null || printf 'unknown\n'
}

boot_collect_uptime() {
  if [[ -r /proc/uptime ]]; then
    awk '{printf "%d\n", $1}' /proc/uptime
    return
  fi
  printf '0\n'
}

boot_collect_load() {
  if [[ -r /proc/loadavg ]]; then
    awk '{print $1, $2, $3}' /proc/loadavg
    return
  fi
  uptime 2>/dev/null | awk -F'load averages?: ' '{print $2}' | tr ',' ' ' | awk '{print $1, $2, $3}' || printf '0 0 0\n'
}

boot_collect_memory() {
  if [[ -r /proc/meminfo ]]; then
    awk '
      /^MemTotal:/ {total=$2}
      /^MemAvailable:/ {available=$2}
      END {
        if (total > 0) printf "%.1f\n", ((total-available)/total)*100;
        else print "0";
      }
    ' /proc/meminfo
    return
  fi
  printf '0\n'
}

boot_collect_disk() {
  df -P / 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); printf "%.1f\n", $5}' || printf '0\n'
}

boot_collect_temperature() {
  if command -v sensors >/dev/null 2>&1; then
    local s
    s="$(sensors 2>/dev/null | awk '/Package id 0|Tctl|CPU/ { for (i=1;i<=NF;i++) if ($i ~ /^\+[0-9.]+°C$/) {gsub(/[+°C]/,"",$i); print $i; exit} }' | head -n1 || true)"
    if [[ -n "$s" ]]; then printf '%s\n' "$s"; return 0; fi
  fi

  local zone value
  for zone in /sys/class/thermal/thermal_zone*/temp; do
    [[ -r "$zone" ]] || continue
    value="$(cat "$zone" 2>/dev/null || true)"
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      awk -v v="$value" 'BEGIN { if (v > 1000) printf "%.1f\n", v/1000; else printf "%.1f\n", v }'
      return 0
    fi
  done

  printf 'null\n'
}

boot_collect_updates() {
  local total=0 security=0

  if command -v apt-get >/dev/null 2>&1 && command -v apt >/dev/null 2>&1; then
    local list
    list="$(apt list --upgradable 2>/dev/null | tail -n +2 || true)"
    total="$(printf '%s\n' "$list" | sed '/^$/d' | wc -l | tr -d ' ')"
    security="$(printf '%s\n' "$list" | grep -Ei 'security|ubuntu-security|debian-security' | wc -l | tr -d ' ')"
  elif command -v dnf >/dev/null 2>&1; then
    total="$(dnf check-update -q 2>/dev/null | awk 'NF>=3 {c++} END {print c+0}' || printf '0')"
    security="$(dnf updateinfo list security 2>/dev/null | awk 'NF>0 {c++} END {print c+0}' || printf '0')"
  elif command -v yum >/dev/null 2>&1; then
    total="$(yum check-update -q 2>/dev/null | awk 'NF>=3 {c++} END {print c+0}' || printf '0')"
    security="$(yum updateinfo list security 2>/dev/null | awk 'NF>0 {c++} END {print c+0}' || printf '0')"
  elif command -v pacman >/dev/null 2>&1; then
    total="$(pacman -Qu 2>/dev/null | wc -l | tr -d ' ')"
    security=0
  fi

  printf '%s %s\n' "${total:-0}" "${security:-0}"
}

boot_collect_reboot_required() {
  if [[ -f /var/run/reboot-required || -f /run/reboot-required ]]; then
    printf 'true\n'
  else
    printf 'false\n'
  fi
}

boot_collect_failed_services() {
  if ! command -v systemctl >/dev/null 2>&1; then
    printf '[]\n'
    return
  fi
  systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}' | sed '/^$/d' | python3 -c 'import json,sys; print(json.dumps([line.strip() for line in sys.stdin if line.strip()]))' 2>/dev/null || printf '[]\n'
}

boot_collect_network() {
  local lan=""
  if command -v hostname >/dev/null 2>&1; then
    lan="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  fi
  if [[ -z "$lan" ]] && command -v ip >/dev/null 2>&1; then
    lan="$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}' || true)"
  fi
  printf '%s\n' "$lan"
}

boot_collect_report_json() {
  command -v python3 >/dev/null 2>&1 || { echo "python3 is required to generate Boot report JSON" >&2; return 127; }

  local hostname kernel uptime load1 load5 load15 ram disk temp updates_total updates_security reboot_required failed_json ip_lan generated_at reports_dir
  hostname="$(boot_collect_hostname)"
  kernel="$(boot_collect_kernel)"
  uptime="$(boot_collect_uptime)"
  read -r load1 load5 load15 <<<"$(boot_collect_load)"
  ram="$(boot_collect_memory)"
  disk="$(boot_collect_disk)"
  temp="$(boot_collect_temperature)"
  read -r updates_total updates_security <<<"$(boot_collect_updates)"
  reboot_required="$(boot_collect_reboot_required)"
  failed_json="$(boot_collect_failed_services)"
  ip_lan="$(boot_collect_network)"
  generated_at="$(date '+%Y-%m-%dT%H:%M:%S%z' | sed -E 's/([0-9]{2})([0-9]{2})$/\1:\2/')"
  reports_dir="${BOOT_REPORTS_DIR:-/var/lib/boot-report/reports}"

  BOOT_HOSTNAME="$hostname" BOOT_KERNEL="$kernel" BOOT_UPTIME_SECONDS="${uptime:-0}" \
  BOOT_LOAD_1="${load1:-0}" BOOT_LOAD_5="${load5:-0}" BOOT_LOAD_15="${load15:-0}" \
  BOOT_RAM_PERCENT="${ram:-0}" BOOT_DISK_PERCENT="${disk:-0}" BOOT_TEMPERATURE="${temp:-null}" \
  BOOT_UPDATES_TOTAL="${updates_total:-0}" BOOT_UPDATES_SECURITY="${updates_security:-0}" \
  BOOT_REBOOT_REQUIRED="${reboot_required:-false}" BOOT_FAILED_SERVICES_JSON="${failed_json:-[]}" \
  BOOT_IP_LAN="$ip_lan" BOOT_GENERATED_AT="$generated_at" BOOT_REPORTS_DIR_VALUE="$reports_dir" \
  BOOT_TELEGRAM_ENABLED="${BOOT_SEND_TELEGRAM:-true}" python3 - <<'PY'
import json, os

def num(name, default=0.0):
    try: return float(os.environ.get(name, default))
    except Exception: return float(default)

def integer(name, default=0):
    try: return int(float(os.environ.get(name, default)))
    except Exception: return int(default)

def boolean(name, default=False):
    return str(os.environ.get(name, str(default))).strip().lower() in ('1','true','yes','y','on','enabled')
try:
    failed = json.loads(os.environ.get('BOOT_FAILED_SERVICES_JSON', '[]'))
    if not isinstance(failed, list): failed = []
except Exception:
    failed = []
ram = round(num('BOOT_RAM_PERCENT'), 1)
disk = round(num('BOOT_DISK_PERCENT'), 1)
load1 = round(num('BOOT_LOAD_1'), 2)
load5 = round(num('BOOT_LOAD_5'), 2)
load15 = round(num('BOOT_LOAD_15'), 2)
updates_total = integer('BOOT_UPDATES_TOTAL')
updates_security = integer('BOOT_UPDATES_SECURITY')
reboot_required = boolean('BOOT_REBOOT_REQUIRED')
failed_count = len(failed)
try: temperature = round(float(os.environ.get('BOOT_TEMPERATURE', 'null')), 1)
except Exception: temperature = None
severity, overall, summary = 'ok', 'ok', 'Servidor estable'
if disk >= 95 or ram >= 95 or failed_count > 0:
    severity, overall, summary = 'critical', 'critical', 'Servidor requiere intervención inmediata'
elif disk >= 85 or ram >= 85 or updates_security > 0 or reboot_required:
    severity, overall, summary = 'warning', 'warning', 'Servidor estable con advertencias operativas'
elif updates_total > 0:
    severity, overall, summary = 'info', 'ok', 'Servidor estable con updates pendientes'
reports_dir = os.environ.get('BOOT_REPORTS_DIR_VALUE', '/var/lib/boot-report/reports').rstrip('/')
report = {
    'module':'boot','schema_version':1,'generated_at':os.environ.get('BOOT_GENERATED_AT',''),
    'server':{'hostname':os.environ.get('BOOT_HOSTNAME','unknown'),'kernel':os.environ.get('BOOT_KERNEL','unknown'),'uptime_seconds':integer('BOOT_UPTIME_SECONDS'),'ip_lan':os.environ.get('BOOT_IP_LAN') or None,'ip_wan':None},
    'status':{'overall':overall,'severity':severity,'summary':summary},
    'metrics':{'cpu_load_1m':load1,'cpu_load_5m':load5,'cpu_load_15m':load15,'ram_used_percent':ram,'disk_root_used_percent':disk,'temperature_c':temperature},
    'updates':{'total':updates_total,'security':updates_security,'reboot_required':reboot_required},
    'services':{'failed_count':failed_count,'failed':failed},
    'telegram':{'enabled':boolean('BOOT_TELEGRAM_ENABLED', True),'last_send_ok':None,'message_id':None,'description':None},
    'artifacts':{'report_json':reports_dir+'/latest/report.json','summary_txt':reports_dir+'/latest/summary.txt'},
}
print(json.dumps(report, ensure_ascii=False, separators=(',',':')))
PY
}

boot_report_set_telegram_result() {
  local json="${1:?report json is required}"
  local enabled="${2:-false}"
  local ok="${3:-null}"
  local message_id="${4:-null}"
  local description="${5:-}"
  BOOT_REPORT_JSON="$json" BOOT_TELEGRAM_ENABLED_VALUE="$enabled" BOOT_TELEGRAM_OK_VALUE="$ok" BOOT_TELEGRAM_MESSAGE_ID_VALUE="$message_id" BOOT_TELEGRAM_DESCRIPTION_VALUE="$description" python3 - <<'PY'
import json, os

def parse_bool_or_none(value):
    value = str(value).strip().lower()
    if value in ('true','1','yes','on'): return True
    if value in ('false','0','no','off'): return False
    return None
try: data = json.loads(os.environ.get('BOOT_REPORT_JSON', '{}'))
except Exception: data = {}
telegram = data.get('telegram') if isinstance(data.get('telegram'), dict) else {}
telegram['enabled'] = bool(parse_bool_or_none(os.environ.get('BOOT_TELEGRAM_ENABLED_VALUE', 'false')))
telegram['last_send_ok'] = parse_bool_or_none(os.environ.get('BOOT_TELEGRAM_OK_VALUE', 'null'))
mid = os.environ.get('BOOT_TELEGRAM_MESSAGE_ID_VALUE', 'null')
try: telegram['message_id'] = int(mid) if mid not in ('','null','None') else None
except Exception: telegram['message_id'] = None
desc = os.environ.get('BOOT_TELEGRAM_DESCRIPTION_VALUE', '')
telegram['description'] = desc or None
data['telegram'] = telegram
print(json.dumps(data, ensure_ascii=False, separators=(',',':')))
PY
}
