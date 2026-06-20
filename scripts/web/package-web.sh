#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST"
tar -C "$ROOT" -czf "$DIST/boot-web.tar.gz" back config database public_html docs README.md FILE_MANIFEST.md
printf 'Generated %s\n' "$DIST/boot-web.tar.gz"
