#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_DIR="${BASE_DIR:-$DIR/../Base}"
source "$BASE_DIR/lib/shell/env.sh"; source "$BASE_DIR/lib/shell/json.sh"; source "$BASE_DIR/lib/shell/log.sh"; source "$BASE_DIR/lib/shell/telegram.sh"; source "$DIR/lib/shell/collect.sh"
export BOOT_SEND_TELEGRAM=false BOOT_REPORTS_DIR="$(mktemp -d)/reports"
json="$(boot_collect_report_json)"
printf '%s' "$json" | python3 -m json.tool >/dev/null
base_json_get_string "$json" module | grep -qx boot
echo "boot_collect_test OK"
