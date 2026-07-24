#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_DIR="${BASE_DIR:-$DIR/../Base}"
source "$BASE_DIR/lib/shell/env.sh"
source "$BASE_DIR/lib/shell/json.sh"
source "$BASE_DIR/lib/shell/log.sh"
source "$BASE_DIR/lib/shell/telegram.sh"
source "$DIR/lib/shell/collect.sh"

export BOOT_SEND_TELEGRAM=false
export BOOT_REPORTS_DIR="$(mktemp -d)/reports"
export BOOT_FILESYSTEM_ALLOWLIST="/"
export BOOT_NETWORK_INTERFACE_ALLOWLIST=""
export BOOT_DISK_DEVICE_ALLOWLIST=""

json="$(boot_collect_report_json)"
printf '%s' "$json" | python3 -m json.tool >/dev/null
BOOT_TEST_JSON="$json" python3 - <<'PY'
import json, os
report = json.loads(os.environ['BOOT_TEST_JSON'])
def check(condition, message):
    if not condition:
        raise SystemExit(message)
check(report['module'] == 'boot', 'unexpected module')
check(report['schema_version'] == 2, 'unexpected schema')
check('cpu_used_percent' in report['metrics'], 'CPU metric missing')
check('swap_used_percent' in report['metrics'], 'swap metric missing')
check(isinstance(report['cpu'], dict), 'CPU detail must be object')
check(isinstance(report['memory'], dict), 'memory detail must be object')
check(isinstance(report['filesystems'], list), 'filesystems must be list')
check(isinstance(report['network_interfaces'], list), 'network interfaces must be list')
check(report['server']['ip_wan'] is None, 'WAN IP must remain null')
PY

echo "boot_collect_test OK"
