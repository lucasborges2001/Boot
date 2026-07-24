#!/usr/bin/env bash
# Allowlisted host-network counters. Rates require a valid previous Boot snapshot.

if [[ -n "${BOOT_COLLECT_NETWORK_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_COLLECT_NETWORK_SH_INCLUDED=1

boot_collect_network_interfaces_json() {
  local generated_at="${1:?generated_at is required}"
  local uptime_seconds="${2:-0}"
  command -v python3 >/dev/null 2>&1 || { printf '[]\n'; return; }

  BOOT_NETWORK_ALLOWLIST_VALUE="${BOOT_NETWORK_INTERFACE_ALLOWLIST:-}" \
  BOOT_NETWORK_SYS_ROOT="${BOOT_SYS_ROOT:-/sys}" \
  BOOT_NETWORK_PREVIOUS_REPORT="${BOOT_REPORTS_DIR:-/var/lib/boot-report/reports}/latest/report.json" \
  BOOT_NETWORK_GENERATED_AT="$generated_at" \
  BOOT_NETWORK_UPTIME="$uptime_seconds" python3 - <<'PY'
import datetime as dt
import json
import os
import re

allowlist = [item.strip() for item in os.environ.get('BOOT_NETWORK_ALLOWLIST_VALUE', '').split(',') if item.strip()]
sys_root = os.environ.get('BOOT_NETWORK_SYS_ROOT', '/sys')
previous_path = os.environ.get('BOOT_NETWORK_PREVIOUS_REPORT', '')
current_generated_at = os.environ.get('BOOT_NETWORK_GENERATED_AT', '')
try:
    current_uptime = int(float(os.environ.get('BOOT_NETWORK_UPTIME', '0')))
except ValueError:
    current_uptime = 0

counter_names = ('rx_bytes', 'tx_bytes', 'rx_packets', 'tx_packets', 'rx_errors', 'tx_errors', 'rx_dropped', 'tx_dropped')
name_pattern = re.compile(r'^[A-Za-z0-9_.:-]+$')

def read_text(path):
    try:
        with open(path, 'r', encoding='utf-8') as handle:
            return handle.read().strip()
    except OSError:
        return None

def read_int(path):
    value = read_text(path)
    try:
        return int(value) if value is not None else None
    except ValueError:
        return None

def parse_time(value):
    if not isinstance(value, str) or not value:
        return None
    try:
        return dt.datetime.fromisoformat(value.replace('Z', '+00:00'))
    except ValueError:
        return None

previous = {}
try:
    with open(previous_path, 'r', encoding='utf-8') as handle:
        decoded = json.load(handle)
        if isinstance(decoded, dict):
            previous = decoded
except (OSError, ValueError, json.JSONDecodeError):
    previous = {}

previous_by_name = {}
for item in previous.get('network_interfaces', []) if isinstance(previous.get('network_interfaces'), list) else []:
    if isinstance(item, dict) and isinstance(item.get('name'), str):
        previous_by_name[item['name']] = item
previous_time = parse_time(previous.get('generated_at'))
current_time = parse_time(current_generated_at)
previous_uptime = (previous.get('server') or {}).get('uptime_seconds') if isinstance(previous.get('server'), dict) else None
try:
    previous_uptime = int(previous_uptime)
except (TypeError, ValueError):
    previous_uptime = None

items = []
for name in allowlist:
    if not name_pattern.fullmatch(name):
        continue
    interface_dir = os.path.join(sys_root, 'class', 'net', name)
    if not os.path.isdir(interface_dir):
        items.append({'name': name, 'available': False, 'rate_status': 'interface_unavailable'})
        continue

    counters = {key: read_int(os.path.join(interface_dir, 'statistics', key)) for key in counter_names}
    speed = read_int(os.path.join(interface_dir, 'speed'))
    if speed is not None and speed < 0:
        speed = None
    item = {
        'name': name,
        'available': True,
        'operstate': read_text(os.path.join(interface_dir, 'operstate')) or 'unknown',
        'speed_mbps': speed,
        'mtu': read_int(os.path.join(interface_dir, 'mtu')),
        'counters': counters,
        'rates': None,
        'rate_status': 'insufficient_samples',
    }

    old = previous_by_name.get(name)
    old_counters = old.get('counters') if isinstance(old, dict) and isinstance(old.get('counters'), dict) else None
    if previous_uptime is not None and current_uptime > 0 and current_uptime < previous_uptime:
        item['rate_status'] = 'reboot_detected'
    elif old_counters is not None and previous_time is not None and current_time is not None:
        interval = (current_time - previous_time).total_seconds()
        if interval <= 0:
            item['rate_status'] = 'invalid_interval'
        elif any(counters.get(key) is None or not isinstance(old_counters.get(key), int) for key in counter_names):
            item['rate_status'] = 'incomplete_counters'
        elif any(counters[key] < old_counters[key] for key in counter_names):
            item['rate_status'] = 'counter_reset'
        else:
            item['rate_status'] = 'ok'
            item['rates'] = {
                'interval_seconds': round(interval, 3),
                'rx_bytes_per_second': round((counters['rx_bytes'] - old_counters['rx_bytes']) / interval, 2),
                'tx_bytes_per_second': round((counters['tx_bytes'] - old_counters['tx_bytes']) / interval, 2),
                'rx_packets_per_second': round((counters['rx_packets'] - old_counters['rx_packets']) / interval, 2),
                'tx_packets_per_second': round((counters['tx_packets'] - old_counters['tx_packets']) / interval, 2),
                'rx_errors_per_second': round((counters['rx_errors'] - old_counters['rx_errors']) / interval, 4),
                'tx_errors_per_second': round((counters['tx_errors'] - old_counters['tx_errors']) / interval, 4),
                'rx_dropped_per_second': round((counters['rx_dropped'] - old_counters['rx_dropped']) / interval, 4),
                'tx_dropped_per_second': round((counters['tx_dropped'] - old_counters['tx_dropped']) / interval, 4),
            }
    items.append(item)

print(json.dumps(items, ensure_ascii=False, separators=(',', ':')))
PY
}
