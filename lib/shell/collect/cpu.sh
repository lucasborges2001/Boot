#!/usr/bin/env bash
# CPU telemetry from procfs with an explicit two-sample utilization window.

if [[ -n "${BOOT_COLLECT_CPU_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_COLLECT_CPU_SH_INCLUDED=1

_boot_cpu_line() {
  local proc_root="${BOOT_PROC_ROOT:-/proc}"
  [[ -r "$proc_root/stat" ]] || return 1
  awk '/^cpu[[:space:]]/ {print; exit}' "$proc_root/stat"
}

_boot_cpu_logical_count() {
  local proc_root="${BOOT_PROC_ROOT:-/proc}"
  if [[ -r "$proc_root/cpuinfo" ]]; then
    local count
    count="$(grep -c '^processor[[:space:]]*:' "$proc_root/cpuinfo" 2>/dev/null || true)"
    if [[ "$count" =~ ^[0-9]+$ && "$count" -gt 0 ]]; then
      printf '%s\n' "$count"
      return
    fi
  fi
  if command -v getconf >/dev/null 2>&1; then
    getconf _NPROCESSORS_ONLN 2>/dev/null || printf '0\n'
    return
  fi
  if command -v nproc >/dev/null 2>&1; then
    nproc 2>/dev/null || printf '0\n'
    return
  fi
  printf '0\n'
}

boot_collect_cpu_json() {
  command -v python3 >/dev/null 2>&1 || { printf '{"available":false,"source":"unavailable"}\n'; return; }

  local interval first second logical
  interval="${BOOT_CPU_SAMPLE_INTERVAL_SECONDS:-0.2}"
  if ! awk -v value="$interval" 'BEGIN { exit !(value ~ /^[0-9]+([.][0-9]+)?$/ && value >= 0 && value <= 5) }'; then
    interval="0.2"
  fi

  first="$(_boot_cpu_line 2>/dev/null || true)"
  if [[ -n "$first" && "$interval" != "0" && "$interval" != "0.0" ]]; then
    sleep "$interval"
  fi
  second="$(_boot_cpu_line 2>/dev/null || true)"
  logical="$(_boot_cpu_logical_count)"

  BOOT_CPU_FIRST="$first" BOOT_CPU_SECOND="$second" BOOT_CPU_LOGICAL="$logical" BOOT_CPU_INTERVAL="$interval" python3 - <<'PY'
import json
import os

FIELDS = ['user', 'nice', 'system', 'idle', 'iowait', 'irq', 'softirq', 'steal', 'guest', 'guest_nice']

def parse(value):
    parts = value.split()
    if not parts or parts[0] != 'cpu':
        return None
    numbers = []
    for raw in parts[1:]:
        try:
            numbers.append(int(raw))
        except ValueError:
            numbers.append(0)
    numbers += [0] * (len(FIELDS) - len(numbers))
    return dict(zip(FIELDS, numbers[:len(FIELDS)]))

def logical_count():
    try:
        value = int(os.environ.get('BOOT_CPU_LOGICAL', '0'))
        return value if value > 0 else None
    except ValueError:
        return None

first = parse(os.environ.get('BOOT_CPU_FIRST', ''))
second = parse(os.environ.get('BOOT_CPU_SECOND', ''))
result = {
    'available': second is not None,
    'source': 'procfs' if second is not None else 'unavailable',
    'logical': logical_count(),
    'sample_window_seconds': None,
    'used_percent': None,
    'time_percent': {
        'user': None,
        'system': None,
        'idle': None,
        'iowait': None,
        'steal': None,
    },
    'counters_jiffies': second or {},
}

if first is not None and second is not None:
    deltas = {name: max(0, second[name] - first[name]) for name in FIELDS}
    total = sum(deltas[name] for name in FIELDS[:8])
    if total > 0:
        idle_all = deltas['idle'] + deltas['iowait']
        result['sample_window_seconds'] = round(float(os.environ.get('BOOT_CPU_INTERVAL', '0')), 3)
        result['used_percent'] = round(max(0.0, min(100.0, (total - idle_all) * 100.0 / total)), 1)
        for name in ('user', 'system', 'idle', 'iowait', 'steal'):
            result['time_percent'][name] = round(deltas[name] * 100.0 / total, 1)

print(json.dumps(result, ensure_ascii=False, separators=(',', ':')))
PY
}
