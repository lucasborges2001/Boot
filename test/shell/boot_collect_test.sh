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
assert report['module'] == 'boot'
assert report['schema_version'] == 2
assert 'cpu_used_percent' in report['metrics']
assert 'swap_used_percent' in report['metrics']
assert isinstance(report['cpu'], dict)
assert isinstance(report['memory'], dict)
assert isinstance(report['filesystems'], list)
assert isinstance(report['network_interfaces'], list)
assert report['server']['ip_wan'] is None
PY

echo "boot_collect_test OK"
