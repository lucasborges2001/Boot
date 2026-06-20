#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_DIR="${BASE_DIR:-$DIR/../Base}"
source "$BASE_DIR/lib/shell/env.sh"; source "$BASE_DIR/lib/shell/json.sh"; source "$BASE_DIR/lib/shell/telegram.sh"; source "$DIR/lib/shell/render.sh"
json="$(cat "$DIR/var/sample-reports/latest/report.json")"
html="$(boot_render_telegram_html "$json")"
printf '%s' "$html" | grep -q '<b>Boot report</b>'
summary="$(boot_render_summary_text "$json")"
printf '%s' "$summary" | grep -q 'Boot report:'
echo "boot_render_test OK"
