#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/shell/collect/cpu.sh"
source "$ROOT/lib/shell/collect/memory.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/proc/pressure"

cat > "$tmp/cpu-first" <<'EOF'
cpu 100 0 50 850 0 0 0 0 0 0
EOF
cat > "$tmp/cpu-second" <<'EOF'
cpu 120 0 60 920 0 0 0 0 0 0
EOF
cat > "$tmp/proc/cpuinfo" <<'EOF'
processor : 0
processor : 1
EOF
cat > "$tmp/proc/meminfo" <<'EOF'
MemTotal:        1000 kB
MemFree:          200 kB
MemAvailable:     400 kB
Buffers:           20 kB
Cached:           100 kB
SwapTotal:        200 kB
SwapFree:         150 kB
EOF
cat > "$tmp/proc/pressure/memory" <<'EOF'
some avg10=0.10 avg60=0.20 avg300=0.30 total=1000
full avg10=0.00 avg60=0.00 avg300=0.01 total=10
EOF

export BOOT_PROC_ROOT="$tmp/proc"
export BOOT_CPU_SAMPLE_FIRST_FILE="$tmp/cpu-first"
export BOOT_CPU_SAMPLE_SECOND_FILE="$tmp/cpu-second"
export BOOT_CPU_SAMPLE_INTERVAL_SECONDS=0.2

cpu_json="$(boot_collect_cpu_json)"
memory_json="$(boot_collect_memory_json)"
BOOT_TEST_CPU="$cpu_json" BOOT_TEST_MEMORY="$memory_json" python3 - <<'PY'
import json, os
cpu = json.loads(os.environ['BOOT_TEST_CPU'])
memory = json.loads(os.environ['BOOT_TEST_MEMORY'])
assert cpu['available'] is True
assert cpu['logical'] == 2
assert cpu['used_percent'] == 30.0
assert cpu['time_percent']['user'] == 20.0
assert cpu['time_percent']['system'] == 10.0
assert cpu['time_percent']['idle'] == 70.0
assert memory['available'] is True
assert memory['total_bytes'] == 1024000
assert memory['used_percent'] == 60.0
assert memory['swap_used_percent'] == 25.0
assert memory['pressure']['source'] == 'procfs_psi'
PY

echo "boot_cpu_memory_test OK"
