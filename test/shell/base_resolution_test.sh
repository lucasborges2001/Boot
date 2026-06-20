#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export BOOT_SEND_TELEGRAM=false
BASE_DIR="${BASE_DIR:-$DIR/../Base}"
test -f "$BASE_DIR/lib/shell/env.sh"
"$DIR/bin/boot-report" --no-telegram --reports-dir "$(mktemp -d)/reports" --print | python3 -m json.tool >/dev/null
echo "base_resolution_test OK"
