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
echo "BOOT_SERVIDOR_UNITS_CONTRACT_PASS"
