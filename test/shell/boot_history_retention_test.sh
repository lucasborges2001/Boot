#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_DIR="${BASE_DIR:-$ROOT/../Base}"
source "$BASE_DIR/lib/shell/json.sh"
source "$ROOT/lib/shell/persist.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
reports="$tmp/reports"
outside="$tmp/outside"
mkdir -p "$outside"
printf 'keep\n' > "$outside/keep.txt"

for minute in 00 01 02 03; do
  json="{\"module\":\"boot\",\"schema_version\":2,\"generated_at\":\"2026-07-24T15:${minute}:00Z\"}"
  boot_persist_report "$json" "summary $minute" "$reports"
done

mkdir -p "$reports/not-a-snapshot"
ln -s "$outside" "$reports/20260724T160000Z-link"
boot_prune_old_reports "$reports" 0 2

test -f "$reports/latest/report.json"
test -f "$outside/keep.txt"
test -d "$reports/not-a-snapshot"
test -L "$reports/20260724T160000Z-link"

count="$(find "$reports" -mindepth 1 -maxdepth 1 -type d -name '20260724T*' | wc -l | tr -d ' ')"
test "$count" = "2"

same='{"module":"boot","schema_version":2,"generated_at":"2026-07-24T17:00:00Z"}'
boot_persist_report "$same" 'first' "$reports"
boot_persist_report "$same" 'second' "$reports"
count_same="$(find "$reports" -mindepth 1 -maxdepth 1 -type d -name '20260724T170000Z*' | wc -l | tr -d ' ')"
test "$count_same" = "2"

echo "boot_history_retention_test OK"
