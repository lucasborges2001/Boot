#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_DIR="${BASE_DIR:-$DIR/../Base}"
source "$BASE_DIR/lib/shell/json.sh"; source "$DIR/lib/shell/persist.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
json="$(cat "$DIR/var/sample-reports/latest/report.json")"
boot_persist_report "$json" 'summary ok' "$tmp/reports"
test -f "$tmp/reports/latest/report.json"
test -f "$tmp/reports/latest/summary.txt"
base_json_file_is_valid "$tmp/reports/latest/report.json"
echo "boot_persist_test OK"
