#!/usr/bin/env bash
# Boot report orchestration. Generic env/json/log/time helpers come from Base.

if [[ -n "${BOOT_COLLECT_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_COLLECT_SH_INCLUDED=1

BOOT_COLLECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BOOT_COLLECT_DIR/collect/system.sh"
source "$BOOT_COLLECT_DIR/collect/cpu.sh"
source "$BOOT_COLLECT_DIR/collect/memory.sh"
source "$BOOT_COLLECT_DIR/collect/storage.sh"
source "$BOOT_COLLECT_DIR/collect/network.sh"

boot_collect_memory() {
  boot_collect_memory_json | python3 -c 'import json,sys; value=json.load(sys.stdin).get("used_percent"); print(0 if value is None else value)'
}

boot_collect_disk() {
  boot_collect_filesystems_json | python3 -c 'import json,sys; items=json.load(sys.stdin); root=next((item for item in items if item.get("mount")=="/"), {}); value=root.get("used_percent"); print(0 if value is None else value)'
}

boot_collect_network() {
  boot_collect_network_lan
}

boot_collect_report_json() {
  command -v python3 >/dev/null 2>&1 || { echo "python3 is required to generate Boot report JSON" >&2; return 127; }

  local generated_at hostname kernel uptime load1 load5 load15 temperature updates_total updates_security
  local reboot_required failed_json ip_lan reports_dir cpu_json memory_json filesystems_json disk_io_json network_json

  generated_at="$(boot_collect_generated_at)"
  hostname="$(boot_collect_hostname)"
  kernel="$(boot_collect_kernel)"
  uptime="$(boot_collect_uptime)"
  read -r load1 load5 load15 <<<"$(boot_collect_load)"
  temperature="$(boot_collect_temperature)"
  read -r updates_total updates_security <<<"$(boot_collect_updates)"
  reboot_required="$(boot_collect_reboot_required)"
  failed_json="$(boot_collect_failed_services)"
  reports_dir="${BOOT_REPORTS_DIR:-/var/lib/boot-report/reports}"

  ip_lan=""
  if [[ "${BOOT_INCLUDE_LAN_IP:-true}" == "true" ]]; then
    ip_lan="$(boot_collect_network_lan)"
  fi

  cpu_json="$(boot_collect_cpu_json)"
  memory_json="$(boot_collect_memory_json)"
  filesystems_json="$(boot_collect_filesystems_json)"
  disk_io_json="$(boot_collect_disk_io_json)"
  network_json="$(boot_collect_network_interfaces_json "$generated_at" "$uptime")"

  BOOT_HOSTNAME_VALUE="$hostname" \
  BOOT_KERNEL_VALUE="$kernel" \
  BOOT_UPTIME_VALUE="${uptime:-0}" \
  BOOT_LOAD_1_VALUE="${load1:-0}" \
  BOOT_LOAD_5_VALUE="${load5:-0}" \
  BOOT_LOAD_15_VALUE="${load15:-0}" \
  BOOT_TEMPERATURE_VALUE="${temperature:-null}" \
  BOOT_UPDATES_TOTAL_VALUE="${updates_total:-0}" \
  BOOT_UPDATES_SECURITY_VALUE="${updates_security:-0}" \
  BOOT_REBOOT_REQUIRED_VALUE="${reboot_required:-false}" \
  BOOT_FAILED_SERVICES_VALUE="${failed_json:-[]}" \
  BOOT_IP_LAN_VALUE="$ip_lan" \
  BOOT_GENERATED_AT_VALUE="$generated_at" \
  BOOT_REPORTS_DIR_VALUE="$reports_dir" \
  BOOT_TELEGRAM_ENABLED_VALUE="${BOOT_SEND_TELEGRAM:-true}" \
  BOOT_CPU_JSON="$cpu_json" \
  BOOT_MEMORY_JSON="$memory_json" \
  BOOT_FILESYSTEMS_JSON="$filesystems_json" \
  BOOT_DISK_IO_JSON="$disk_io_json" \
  BOOT_NETWORK_JSON="$network_json" python3 - <<'PY'
import json
import os


def number(name, default=0.0):
    try:
        return float(os.environ.get(name, default))
    except (TypeError, ValueError):
        return float(default)


def integer(name, default=0):
    try:
        return int(float(os.environ.get(name, default)))
    except (TypeError, ValueError):
        return int(default)


def boolean_value(value, default=False):
    normalized = str(value if value is not None else default).strip().lower()
    return normalized in ('1', 'true', 'yes', 'y', 'on', 'enabled')


def decode(name, default):
    try:
        value = json.loads(os.environ.get(name, ''))
        return value if isinstance(value, type(default)) else default
    except (TypeError, ValueError, json.JSONDecodeError):
        return default


cpu = decode('BOOT_CPU_JSON', {})
memory = decode('BOOT_MEMORY_JSON', {})
filesystems = decode('BOOT_FILESYSTEMS_JSON', [])
disk_io = decode('BOOT_DISK_IO_JSON', {})
network_interfaces = decode('BOOT_NETWORK_JSON', [])
failed = decode('BOOT_FAILED_SERVICES_VALUE', [])

root_filesystem = next((item for item in filesystems if item.get('mount') == '/' and item.get('available')), {})
ram_percent = memory.get('used_percent')
swap_percent = memory.get('swap_used_percent')
disk_percent = root_filesystem.get('used_percent')
cpu_percent = cpu.get('used_percent')
try:
    temperature = round(float(os.environ.get('BOOT_TEMPERATURE_VALUE', 'null')), 1)
except (TypeError, ValueError):
    temperature = None

updates_total = integer('BOOT_UPDATES_TOTAL_VALUE')
updates_security = integer('BOOT_UPDATES_SECURITY_VALUE')
reboot_required = boolean_value(os.environ.get('BOOT_REBOOT_REQUIRED_VALUE'))
failed_count = len(failed)

warnings = []
if cpu.get('available') is not True:
    warnings.append('cpu_unavailable')
if memory.get('available') is not True:
    warnings.append('memory_unavailable')
if not root_filesystem:
    warnings.append('root_filesystem_unavailable')
for interface in network_interfaces:
    if interface.get('available') is not True:
        warnings.append('network_interface_unavailable:' + str(interface.get('name', 'unknown')))

severity, overall, summary = 'ok', 'ok', 'Servidor estable'
filesystem_critical = any((item.get('used_percent') or 0) >= 95 for item in filesystems if item.get('available'))
filesystem_warning = any((item.get('used_percent') or 0) >= 85 for item in filesystems if item.get('available'))
if filesystem_critical or (ram_percent or 0) >= 95 or (cpu_percent or 0) >= 98 or failed_count > 0:
    severity, overall, summary = 'critical', 'critical', 'Servidor requiere intervención inmediata'
elif filesystem_warning or (ram_percent or 0) >= 85 or (cpu_percent or 0) >= 90 or updates_security > 0 or reboot_required:
    severity, overall, summary = 'warning', 'warning', 'Servidor estable con advertencias operativas'
elif updates_total > 0 or warnings:
    severity, overall, summary = 'info', 'ok', 'Servidor estable con información operativa pendiente'

reports_dir = os.environ.get('BOOT_REPORTS_DIR_VALUE', '/var/lib/boot-report/reports').rstrip('/')
report = {
    'module': 'boot',
    'schema_version': 2,
    'generated_at': os.environ.get('BOOT_GENERATED_AT_VALUE', ''),
    'server': {
        'hostname': os.environ.get('BOOT_HOSTNAME_VALUE', 'unknown'),
        'kernel': os.environ.get('BOOT_KERNEL_VALUE', 'unknown'),
        'uptime_seconds': integer('BOOT_UPTIME_VALUE'),
        'cpu_logical': cpu.get('logical'),
        'ip_lan': os.environ.get('BOOT_IP_LAN_VALUE') or None,
        'ip_wan': None,
    },
    'status': {
        'overall': overall,
        'severity': severity,
        'summary': summary,
    },
    'metrics': {
        'cpu_used_percent': cpu_percent,
        'cpu_load_1m': round(number('BOOT_LOAD_1_VALUE'), 2),
        'cpu_load_5m': round(number('BOOT_LOAD_5_VALUE'), 2),
        'cpu_load_15m': round(number('BOOT_LOAD_15_VALUE'), 2),
        'ram_used_percent': ram_percent,
        'swap_used_percent': swap_percent,
        'disk_root_used_percent': disk_percent,
        'temperature_c': temperature,
    },
    'cpu': cpu,
    'memory': memory,
    'filesystems': filesystems,
    'disk_io': disk_io,
    'network_interfaces': network_interfaces,
    'updates': {
        'total': updates_total,
        'security': updates_security,
        'reboot_required': reboot_required,
    },
    'services': {
        'failed_count': failed_count,
        'failed': failed,
    },
    'collection': {
        'warnings': warnings,
        'network_rates_require_previous_snapshot': True,
    },
    'units': {
        'percent': '0..100',
        'bytes': 'bytes',
        'rates': 'per_second',
        'load_average': 'runnable_tasks_average',
        'temperature': 'celsius',
        'cpu_counters': 'jiffies',
    },
    'telegram': {
        'enabled': boolean_value(os.environ.get('BOOT_TELEGRAM_ENABLED_VALUE'), True),
        'last_send_ok': None,
        'message_id': None,
        'description': None,
    },
    'artifacts': {
        'report_json': reports_dir + '/latest/report.json',
        'summary_txt': reports_dir + '/latest/summary.txt',
    },
}
print(json.dumps(report, ensure_ascii=False, separators=(',', ':')))
PY
}

boot_report_set_telegram_result() {
  local json="${1:?report json is required}"
  local enabled="${2:-false}"
  local ok="${3:-null}"
  local message_id="${4:-null}"
  local description="${5:-}"
  BOOT_REPORT_JSON="$json" BOOT_TELEGRAM_ENABLED_VALUE="$enabled" BOOT_TELEGRAM_OK_VALUE="$ok" BOOT_TELEGRAM_MESSAGE_ID_VALUE="$message_id" BOOT_TELEGRAM_DESCRIPTION_VALUE="$description" python3 - <<'PY'
import json
import os


def parse_bool_or_none(value):
    value = str(value).strip().lower()
    if value in ('true', '1', 'yes', 'on'):
        return True
    if value in ('false', '0', 'no', 'off'):
        return False
    return None

try:
    data = json.loads(os.environ.get('BOOT_REPORT_JSON', '{}'))
except (TypeError, ValueError, json.JSONDecodeError):
    data = {}
telegram = data.get('telegram') if isinstance(data.get('telegram'), dict) else {}
telegram['enabled'] = bool(parse_bool_or_none(os.environ.get('BOOT_TELEGRAM_ENABLED_VALUE', 'false')))
telegram['last_send_ok'] = parse_bool_or_none(os.environ.get('BOOT_TELEGRAM_OK_VALUE', 'null'))
message_id = os.environ.get('BOOT_TELEGRAM_MESSAGE_ID_VALUE', 'null')
try:
    telegram['message_id'] = int(message_id) if message_id not in ('', 'null', 'None') else None
except ValueError:
    telegram['message_id'] = None
telegram['description'] = os.environ.get('BOOT_TELEGRAM_DESCRIPTION_VALUE', '') or None
data['telegram'] = telegram
print(json.dumps(data, ensure_ascii=False, separators=(',', ':')))
PY
}
