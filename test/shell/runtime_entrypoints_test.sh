#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

grep -q 'lib/shell/collect.sh' "$DIR/bin/boot-report"
grep -q 'lib/shell/render.sh' "$DIR/bin/boot-report"
grep -q 'lib/shell/persist.sh' "$DIR/bin/boot-report"

bash -n "$DIR/lib/render.sh"
bash -n "$DIR/lib/system.sh"
for file in "$DIR"/lib/render/*.sh "$DIR"/lib/system/*.sh; do
  bash -n "$file"
done

echo "runtime_entrypoints_test OK"
