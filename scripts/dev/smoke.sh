#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
find "$DIR" -name '*.php' -print0 | xargs -0 -n1 php -l >/dev/null
for test_file in "$DIR"/test/shell/*.sh; do bash "$test_file"; done
for test_file in "$DIR"/test/php/*.php; do php "$test_file"; done
"$DIR/bin/boot-report-test" >/dev/null
echo "Boot smoke OK"
