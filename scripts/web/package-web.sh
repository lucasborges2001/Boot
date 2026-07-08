#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST"

paths=(
  back
  config
  database
  public_html
  docs
  README.md
  FILE_MANIFEST.md
  DELETE_MANIFEST.md
)

existing=()
for path in "${paths[@]}"; do
  if [[ -e "$ROOT/$path" ]]; then
    existing+=("$path")
  fi
done

if [[ ! -f "$ROOT/public_html/api/health.php" ]]; then
  echo "ERROR: required web endpoint missing: public_html/api/health.php" >&2
  exit 1
fi

if [[ ${#existing[@]} -eq 0 ]]; then
  echo "ERROR: no web package paths found" >&2
  exit 1
fi

tar -C "$ROOT" -czf "$DIST/boot-web.tar.gz" "${existing[@]}"
printf 'Generated %s\n' "$DIST/boot-web.tar.gz"
