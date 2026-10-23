#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RENDER="$ROOT/scripts/server/render-servidor-units.py"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
SRV=/home/tecnicosfivisa/servidor
python3 -B "$RENDER" --root "$SRV" --unit boot-report.service >"$TMP/boot.service"
python3 -B "$RENDER" --root "$SRV" --unit boot-report.timer >"$TMP/boot.timer"
grep -Fxq "ExecStart=$SRV/current/boot/bin/boot-report" "$TMP/boot.service"
grep -Fxq "Environment=BASE_DIR=$SRV/current/base" "$TMP/boot.service"
grep -Fxq "Environment=BOOT_SERVIDOR_ROOT=$SRV" "$TMP/boot.service"
grep -Fxq "Environment=BOOT_REPORTS_DIR=$SRV/state/boot/reports" "$TMP/boot.service"
grep -Fxq "EnvironmentFile=$SRV/config/boot/server.env" "$TMP/boot.service"
if grep -Fq "EnvironmentFile=-$SRV/config/boot/server.env" "$TMP/boot.service"; then
  echo "FAIL: private server.env must be required" >&2
  exit 1
fi
grep -Fxq "ReadWritePaths=$SRV/state/boot" "$TMP/boot.service"
grep -Fxq "ProtectHome=read-only" "$TMP/boot.service"
grep -Fxq "User=bootreport" "$TMP/boot.service"
grep -Fxq "OnCalendar=*-*-* 08:30:00" "$TMP/boot.timer"
if grep -Eq '^On(UnitActiveSec|BootSec)=' "$TMP/boot.timer"; then
  echo "FAIL: servidor timer changed Boot cadence to interval" >&2
  exit 1
fi
grep -Fxq "Unit=boot-report.service" "$TMP/boot.timer"
if python3 -B "$RENDER" --root /opt/boot-report --unit boot-report.service >"$TMP/invalid" 2>/dev/null; then
  echo "FAIL: unsafe root accepted" >&2
  exit 1
fi
if python3 -B "$RENDER" --root "$SRV" --unit unexpected.service >"$TMP/invalid" 2>/dev/null; then
  echo "FAIL: unexpected unit accepted" >&2
  exit 1
fi
# Fail-closed checks run before Base loading, persistence, and Telegram.
reject_boot_config() {
  local expected="$1"
  shift
  if env -i PATH="$PATH" "$@" "$ROOT/bin/boot-report" --no-telegram --print >"$TMP/rejected.stdout" 2>"$TMP/rejected.stderr"; then
    echo "FAIL: rejected Boot servidor config was accepted" >&2
    exit 1
  fi
  if ! grep -Fq "$expected" "$TMP/rejected.stderr"; then
    cat "$TMP/rejected.stderr" >&2
    echo "FAIL: expected rejection: $expected" >&2
    exit 1
  fi
}
reject_boot_config "Invalid Boot servidor root" BOOT_SERVIDOR_ROOT=/tmp/not-servidor
reject_boot_config "managed BASE_DIR and BOOT_REPORTS_DIR" BOOT_SERVIDOR_ROOT="$SRV" BASE_DIR=/opt/base BOOT_REPORTS_DIR="$SRV/state/boot/reports"
reject_boot_config "managed BASE_DIR and BOOT_REPORTS_DIR" BOOT_SERVIDOR_ROOT="$SRV" BASE_DIR="$SRV/current/base" BOOT_REPORTS_DIR=/var/lib/boot-report/reports
reject_boot_config "lock file must stay" BOOT_SERVIDOR_ROOT="$SRV" BASE_DIR="$SRV/current/base" BOOT_REPORTS_DIR="$SRV/state/boot/reports" BOOT_LOCK_FILE=/tmp/boot.lock
if env -i PATH="$PATH" BOOT_SERVIDOR_ROOT="$SRV" BASE_DIR="$SRV/current/base" BOOT_REPORTS_DIR="$SRV/state/boot/reports" "$ROOT/bin/boot-report" --env /tmp/unmanaged.env --no-telegram --print >"$TMP/rejected.stdout" 2>"$TMP/rejected.stderr"; then
  echo "FAIL: servidor --env accepted" >&2
  exit 1
fi
grep -Fq "Boot servidor forbids --env" "$TMP/rejected.stderr"
# Regression contract: writes must not follow pre-existing symlinks.
grep -Fq '"$BOOT_EXPECTED_REPORTS_DIR/latest"' "$ROOT/bin/boot-report"
grep -Fq '"$BOOT_EXPECTED_REPORTS_DIR/.boot-report.lock"' "$ROOT/bin/boot-report"
echo "BOOT_SERVIDOR_UNITS_CONTRACT_PASS"
