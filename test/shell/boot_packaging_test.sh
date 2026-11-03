#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Run legacy packaging against a disposable committed tree, not the local
# dist/ directory that can hold immutable SHA-bound servidor artifacts.
source_dir="$tmp/source"
mkdir -- "$source_dir"
git -C "$DIR" archive --format=tar HEAD | tar -xf - -C "$source_dir"
bash "$source_dir/bin/boot-report-package" >/dev/null

tar -tzf "$source_dir/dist/boot-server.tar.gz" > "$tmp/boot-server.files"
tar -tzf "$source_dir/dist/boot-web.tar.gz" > "$tmp/boot-web.files"

grep -qx 'bin/boot-report' "$tmp/boot-server.files"
grep -qx 'public_html/api/health.php' "$tmp/boot-web.files"

echo "boot_packaging_test OK"
