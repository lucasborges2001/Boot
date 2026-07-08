#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST"

paths=(
  bin
  lib
  config
  scripts/server
  systemd
  README-INSTALL.md
  README.md
  FILE_MANIFEST.md
  DELETE_MANIFEST.md
  boot-report.sh
)

existing=()
for path in "${paths[@]}"; do
  if [[ -e "$ROOT/$path" ]]; then
    existing+=("$path")
  fi
done

if [[ ! -x "$ROOT/bin/boot-report" ]]; then
  echo "ERROR: required server entrypoint missing or not executable: bin/boot-report" >&2
  exit 1
fi

if [[ ${#existing[@]} -eq 0 ]]; then
  echo "ERROR: no server package paths found" >&2
  exit 1
fi

tar -C "$ROOT" -czf "$DIST/boot-server.tar.gz" "${existing[@]}"
printf 'Generated %s\n' "$DIST/boot-server.tar.gz"
