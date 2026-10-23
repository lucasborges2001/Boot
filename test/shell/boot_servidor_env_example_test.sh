#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="$ROOT/config/servidor.env.example"
SRV=/home/tecnicosfivisa/servidor
for line in \
  "BOOT_SERVIDOR_ROOT=$SRV" \
  "BASE_DIR=$SRV/current/base" \
  "BOOT_REPORTS_DIR=$SRV/state/boot/reports" \
  "BOOT_LOCK_FILE=$SRV/state/boot/reports/.boot-report.lock" \
  'BOOT_SEND_TELEGRAM=false'; do
  [[ "$(grep -Fxc "$line" "$FILE")" == 1 ]] || { echo "FAIL: missing or duplicate Boot env line: $line" >&2; exit 1; }
done
if grep -Eq '^[[:space:]]*(TELEGRAM_BOT_TOKEN|TELEGRAM_CHAT_ID|BOT_TOKEN|CHAT_ID)=' "$FILE"; then
  echo 'FAIL: credentials must not be in Boot template' >&2; exit 1
fi
if grep -Eq '^([A-Z_]+)=/(opt|var/lib|var/log|etc)/' "$FILE"; then
  echo 'FAIL: legacy path in Boot servidor template' >&2; exit 1
fi
echo BOOT_SERVIDOR_ENV_EXAMPLE_PASS
