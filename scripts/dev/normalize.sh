#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chmod +x "$DIR/bin/"* "$DIR/scripts/server/"*.sh "$DIR/scripts/web/"*.sh "$DIR/scripts/dev/"*.sh "$DIR/test/shell/"*.sh "$DIR/boot-report.sh"
