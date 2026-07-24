#!/usr/bin/env bash
# Boot-specific rendering. Telegram escaping comes from Base.

if [[ -n "${BOOT_RENDER_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_RENDER_SH_INCLUDED=1

_boot_json_value() {
  local json="$1" path="$2" default="${3:-}"
  base_json_get_string "$json" "$path" 2>/dev/null || printf '%s' "$default"
}

boot_render_telegram_html() {
  local json="${1:?report json is required}"
  local hostname severity summary generated_at cpu load1 load5 load15 ram swap disk updates security reboot failed temp
  hostname="$(_boot_json_value "$json" 'server.hostname' 'unknown')"
  severity="$(_boot_json_value "$json" 'status.severity' 'unknown')"
  summary="$(_boot_json_value "$json" 'status.summary' 'Sin resumen')"
  generated_at="$(_boot_json_value "$json" 'generated_at' '')"
  cpu="$(_boot_json_value "$json" 'metrics.cpu_used_percent' 'n/a')"
  load1="$(_boot_json_value "$json" 'metrics.cpu_load_1m' 'n/a')"
  load5="$(_boot_json_value "$json" 'metrics.cpu_load_5m' 'n/a')"
  load15="$(_boot_json_value "$json" 'metrics.cpu_load_15m' 'n/a')"
  ram="$(_boot_json_value "$json" 'metrics.ram_used_percent' 'n/a')"
  swap="$(_boot_json_value "$json" 'metrics.swap_used_percent' 'n/a')"
  disk="$(_boot_json_value "$json" 'metrics.disk_root_used_percent' 'n/a')"
  temp="$(_boot_json_value "$json" 'metrics.temperature_c' 'n/a')"
  updates="$(_boot_json_value "$json" 'updates.total' '0')"
  security="$(_boot_json_value "$json" 'updates.security' '0')"
  reboot="$(_boot_json_value "$json" 'updates.reboot_required' 'false')"
  failed="$(_boot_json_value "$json" 'services.failed_count' '0')"
  cat <<TXT
<b>Boot report</b> · <code>$(base_telegram_escape_html "$hostname")</code>
Estado: <b>$(base_telegram_escape_html "$severity")</b>
$(base_telegram_escape_html "$summary")
CPU: <code>$(base_telegram_escape_html "$cpu")%</code> · Load: <code>$(base_telegram_escape_html "$load1")</code> / <code>$(base_telegram_escape_html "$load5")</code> / <code>$(base_telegram_escape_html "$load15")</code>
RAM: <code>$(base_telegram_escape_html "$ram")%</code> · Swap: <code>$(base_telegram_escape_html "$swap")%</code> · Disco: <code>$(base_telegram_escape_html "$disk")%</code>
Temp: <code>$(base_telegram_escape_html "$temp")°C</code>
Updates: <code>$(base_telegram_escape_html "$updates")</code> · Security: <code>$(base_telegram_escape_html "$security")</code> · Reboot: <code>$(base_telegram_escape_html "$reboot")</code>
Servicios fallidos: <code>$(base_telegram_escape_html "$failed")</code>
Generado: <code>$(base_telegram_escape_html "$generated_at")</code>
TXT
}

boot_render_summary_text() {
  local json="${1:?report json is required}"
  BOOT_REPORT_JSON="$json" python3 - <<'PY'
import json
import os

try:
    report = json.loads(os.environ.get('BOOT_REPORT_JSON', '{}'))
except (TypeError, ValueError, json.JSONDecodeError):
    report = {}
server = report.get('server') or {}
status = report.get('status') or {}
metrics = report.get('metrics') or {}
updates = report.get('updates') or {}
services = report.get('services') or {}
telegram = report.get('telegram') or {}
filesystems = report.get('filesystems') if isinstance(report.get('filesystems'), list) else []
interfaces = report.get('network_interfaces') if isinstance(report.get('network_interfaces'), list) else []
lines = [
    f"Boot report: {server.get('hostname', 'unknown')}",
    f"Schema version: {report.get('schema_version', 'unknown')}",
    f"Generated at: {report.get('generated_at', '')}",
    f"Status: {status.get('severity', 'unknown')} - {status.get('summary', '')}",
    f"Uptime seconds: {server.get('uptime_seconds', 0)}",
    f"CPU used: {metrics.get('cpu_used_percent', 'n/a')}% logical={server.get('cpu_logical', 'n/a')}",
    f"Load: {metrics.get('cpu_load_1m', 'n/a')} / {metrics.get('cpu_load_5m', 'n/a')} / {metrics.get('cpu_load_15m', 'n/a')}",
    f"RAM used: {metrics.get('ram_used_percent', 'n/a')}%",
    f"Swap used: {metrics.get('swap_used_percent', 'n/a')}%",
    f"Disk root used: {metrics.get('disk_root_used_percent', 'n/a')}%",
    f"Filesystems collected: {len(filesystems)}",
    f"Network interfaces collected: {len(interfaces)}",
    f"Temperature: {metrics.get('temperature_c', 'n/a')} C",
    f"Updates: total={updates.get('total', 0)} security={updates.get('security', 0)} reboot_required={updates.get('reboot_required', False)}",
    f"Failed services: {services.get('failed_count', 0)}",
    f"Telegram: enabled={telegram.get('enabled')} last_send_ok={telegram.get('last_send_ok')} message_id={telegram.get('message_id')}",
]
print('\n'.join(lines))
PY
}
