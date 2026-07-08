#!/usr/bin/env bash
# Disco legacy para Boot.

sys_smartctl_status() {
  local status="UNKNOWN"
  if command -v smartctl >/dev/null 2>&1; then
    local dev result
    for dev in /dev/sda /dev/nvme0n1 /dev/sdb; do
      if [[ ! -e "$dev" ]]; then continue; fi
      result="$(smartctl -H "$dev" 2>/dev/null || smartctl -H "$dev" -d auto 2>/dev/null || true)"
      if echo "$result" | grep -qi "overall.*health.*passed"; then
        status="PASS"
        break
      elif echo "$result" | grep -qi "overall.*health.*failed"; then
        status="FAIL"
        break
      fi
    done
  fi
  echo "$status"
}
