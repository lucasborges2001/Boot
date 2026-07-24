#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/shell/collect/network.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/sys/class/net/eth0/statistics" "$tmp/reports/latest"

printf 'up\n' > "$tmp/sys/class/net/eth0/operstate"
printf '1000\n' > "$tmp/sys/class/net/eth0/speed"
printf '1500\n' > "$tmp/sys/class/net/eth0/mtu"
for pair in \
  rx_bytes:2000 tx_bytes:4000 rx_packets:200 tx_packets:400 \
  rx_errors:0 tx_errors:0 rx_dropped:2 tx_dropped:0; do
  name="${pair%%:*}"
  value="${pair#*:}"
  printf '%s\n' "$value" > "$tmp/sys/class/net/eth0/statistics/$name"
done

cat > "$tmp/reports/latest/report.json" <<'JSON'
{
  "module": "boot",
  "schema_version": 2,
  "generated_at": "2026-07-24T15:00:00Z",
  "server": {"uptime_seconds": 100},
  "network_interfaces": [{
    "name": "eth0",
    "counters": {
      "rx_bytes": 1000,
      "tx_bytes": 1000,
      "rx_packets": 100,
      "tx_packets": 100,
      "rx_errors": 0,
      "tx_errors": 0,
      "rx_dropped": 1,
      "tx_dropped": 0
    }
  }]
}
JSON

export BOOT_SYS_ROOT="$tmp/sys"
export BOOT_REPORTS_DIR="$tmp/reports"
export BOOT_NETWORK_INTERFACE_ALLOWLIST="eth0"

json="$(boot_collect_network_interfaces_json '2026-07-24T15:01:00Z' 160)"
BOOT_TEST_JSON="$json" python3 - <<'PY'
import json, os
item = json.loads(os.environ['BOOT_TEST_JSON'])[0]
assert item['rate_status'] == 'ok'
assert item['rates']['interval_seconds'] == 60.0
assert item['rates']['rx_bytes_per_second'] == 16.67
assert item['rates']['tx_bytes_per_second'] == 50.0
PY

printf '500\n' > "$tmp/sys/class/net/eth0/statistics/rx_bytes"
json="$(boot_collect_network_interfaces_json '2026-07-24T15:02:00Z' 220)"
BOOT_TEST_JSON="$json" python3 - <<'PY'
import json, os
item = json.loads(os.environ['BOOT_TEST_JSON'])[0]
assert item['rate_status'] == 'counter_reset'
assert item['rates'] is None
PY

printf '2000\n' > "$tmp/sys/class/net/eth0/statistics/rx_bytes"
json="$(boot_collect_network_interfaces_json '2026-07-24T15:02:00Z' 50)"
BOOT_TEST_JSON="$json" python3 - <<'PY'
import json, os
item = json.loads(os.environ['BOOT_TEST_JSON'])[0]
assert item['rate_status'] == 'reboot_detected'
assert item['rates'] is None
PY

echo "boot_network_rates_test OK"
