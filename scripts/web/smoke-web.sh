#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
find "$DIR/back" "$DIR/public_html" -name '*.php' -print0 | xargs -0 -n1 php -l >/dev/null
echo "web smoke OK"
