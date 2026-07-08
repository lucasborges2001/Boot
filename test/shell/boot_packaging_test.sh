#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

rm -rf "$DIR/dist"
bash "$DIR/bin/boot-report-package" >/dev/null

tar -tzf "$DIR/dist/boot-server.tar.gz" > "$tmp/boot-server.files"
tar -tzf "$DIR/dist/boot-web.tar.gz" > "$tmp/boot-web.files"

grep -qx 'bin/boot-report' "$tmp/boot-server.files"
grep -qx 'public_html/api/health.php' "$tmp/boot-web.files"

echo "boot_packaging_test OK"
