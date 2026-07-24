#!/usr/bin/env bash
# Memory, swap and optional PSI telemetry from procfs.

if [[ -n "${BOOT_COLLECT_MEMORY_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_COLLECT_MEMORY_SH_INCLUDED=1

boot_collect_memory_json() {
  command -v python3 >/dev/null 2>&1 || { printf '{"available":false,"source":"unavailable"}\n'; return; }

  BOOT_MEMORY_PROC_ROOT="${BOOT_PROC_ROOT:-/proc}" python3 - <<'PY'
import json
import os
import re

proc_root = os.environ.get('BOOT_MEMORY_PROC_ROOT', '/proc')
meminfo_path = os.path.join(proc_root, 'meminfo')
pressure_path = os.path.join(proc_root, 'pressure', 'memory')
values = {}

try:
    with open(meminfo_path, 'r', encoding='utf-8') as handle:
        for line in handle:
            match = re.match(r'^([A-Za-z_()]+):\s+(\d+)\s*(kB)?', line)
            if match:
                multiplier = 1024 if match.group(3) == 'kB' else 1
                values[match.group(1)] = int(match.group(2)) * multiplier
except OSError:
    values = {}

def percent(used, total):
    if total <= 0:
        return None
    return round(max(0.0, min(100.0, used * 100.0 / total)), 1)

total = values.get('MemTotal', 0)
available = values.get('MemAvailable')
if available is None:
    available = values.get('MemFree', 0) + values.get('Buffers', 0) + values.get('Cached', 0)
used = max(0, total - available)
swap_total = values.get('SwapTotal', 0)
swap_free = values.get('SwapFree', 0)
swap_used = max(0, swap_total - swap_free)

pressure = None
try:
    parsed = {}
    with open(pressure_path, 'r', encoding='utf-8') as handle:
        for line in handle:
            parts = line.split()
            if not parts:
                continue
            row = {}
            for token in parts[1:]:
                if '=' not in token:
                    continue
                key, value = token.split('=', 1)
                try:
                    row[key] = float(value) if key.startswith('avg') else int(value)
                except ValueError:
                    continue
            parsed[parts[0]] = row
    if parsed:
        pressure = {'source': 'procfs_psi', **parsed}
except OSError:
    pressure = None

result = {
    'available': total > 0,
    'source': 'procfs' if total > 0 else 'unavailable',
    'total_bytes': total if total > 0 else None,
    'available_bytes': available if total > 0 else None,
    'used_bytes': used if total > 0 else None,
    'used_percent': percent(used, total),
    'swap_total_bytes': swap_total if total > 0 else None,
    'swap_used_bytes': swap_used if total > 0 else None,
    'swap_used_percent': percent(swap_used, swap_total) if swap_total > 0 else 0.0 if total > 0 else None,
    'pressure': pressure,
}
print(json.dumps(result, ensure_ascii=False, separators=(',', ':')))
PY
}
