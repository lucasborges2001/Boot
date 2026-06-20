#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST"
tar -C "$ROOT" -czf "$DIST/boot-server.tar.gz" bin lib config scripts/server systemd README-INSTALL.md README.md FILE_MANIFEST.md DELETE_MANIFEST.md boot-report.sh
printf 'Generated %s\n' "$DIST/boot-server.tar.gz"
