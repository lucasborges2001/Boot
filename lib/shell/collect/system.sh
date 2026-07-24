#!/usr/bin/env bash
# Boot-specific operating-system collectors. Generic helpers remain in Base.

if [[ -n "${BOOT_COLLECT_SYSTEM_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_COLLECT_SYSTEM_SH_INCLUDED=1

boot_command_timeout_seconds() {
  local value="${BOOT_COMMAND_TIMEOUT_SECONDS:-5}"
  if [[ ! "$value" =~ ^[0-9]+$ || "$value" -lt 1 || "$value" -gt 300 ]]; then
    value=5
  fi
  printf '%s\n' "$value"
}

boot_run_with_timeout() {
  local seconds
  seconds="$(boot_command_timeout_seconds)"
  if command -v timeout >/dev/null 2>&1; then
    timeout --signal=TERM --kill-after=2 "${seconds}s" "$@"
  else
    "$@"
  fi
}

boot_collect_generated_at() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

boot_collect_hostname() {
  boot_run_with_timeout hostname -f 2>/dev/null \
    || boot_run_with_timeout hostname 2>/dev/null \
    || printf 'unknown\n'
}

boot_collect_kernel() {
  uname -r 2>/dev/null || printf 'unknown\n'
}

boot_collect_uptime() {
  local proc_root="${BOOT_PROC_ROOT:-/proc}"
  if [[ -r "$proc_root/uptime" ]]; then
    awk '{printf "%d\n", $1}' "$proc_root/uptime"
    return
  fi
  printf '0\n'
}

boot_collect_load() {
  local proc_root="${BOOT_PROC_ROOT:-/proc}"
  if [[ -r "$proc_root/loadavg" ]]; then
    awk '{print $1, $2, $3}' "$proc_root/loadavg"
    return
  fi
  boot_run_with_timeout uptime 2>/dev/null \
    | awk -F'load averages?: ' '{print $2}' \
    | tr ',' ' ' \
    | awk '{print $1, $2, $3}' \
    || printf '0 0 0\n'
}

boot_collect_temperature() {
  local sys_root="${BOOT_SYS_ROOT:-/sys}"
  if command -v sensors >/dev/null 2>&1; then
    local sensor_value
    sensor_value="$(boot_run_with_timeout sensors 2>/dev/null | awk '/Package id 0|Tctl|CPU/ { for (i=1;i<=NF;i++) if ($i ~ /^\+[0-9.]+°C$/) {gsub(/[+°C]/,"",$i); print $i; exit} }' | head -n1 || true)"
    if [[ -n "$sensor_value" ]]; then
      printf '%s\n' "$sensor_value"
      return 0
    fi
  fi

  local zone value
  for zone in "$sys_root"/class/thermal/thermal_zone*/temp; do
    [[ -r "$zone" ]] || continue
    value="$(cat "$zone" 2>/dev/null || true)"
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      awk -v v="$value" 'BEGIN { if (v > 1000) printf "%.1f\n", v/1000; else printf "%.1f\n", v }'
      return 0
    fi
  done

  printf 'null\n'
}

boot_collect_updates() {
  local total=0 security=0 list=""

  if command -v apt-get >/dev/null 2>&1 && command -v apt >/dev/null 2>&1; then
    list="$(boot_run_with_timeout apt list --upgradable 2>/dev/null | tail -n +2 || true)"
    total="$(printf '%s\n' "$list" | awk 'NF {count++} END {print count+0}')"
    security="$(printf '%s\n' "$list" | awk 'BEGIN {IGNORECASE=1} /security|ubuntu-security|debian-security/ {count++} END {print count+0}')"
  elif command -v dnf >/dev/null 2>&1; then
    list="$(boot_run_with_timeout dnf check-update -q 2>/dev/null || true)"
    total="$(printf '%s\n' "$list" | awk 'NF>=3 {count++} END {print count+0}')"
    list="$(boot_run_with_timeout dnf updateinfo list security 2>/dev/null || true)"
    security="$(printf '%s\n' "$list" | awk 'NF>0 {count++} END {print count+0}')"
  elif command -v yum >/dev/null 2>&1; then
    list="$(boot_run_with_timeout yum check-update -q 2>/dev/null || true)"
    total="$(printf '%s\n' "$list" | awk 'NF>=3 {count++} END {print count+0}')"
    list="$(boot_run_with_timeout yum updateinfo list security 2>/dev/null || true)"
    security="$(printf '%s\n' "$list" | awk 'NF>0 {count++} END {print count+0}')"
  elif command -v pacman >/dev/null 2>&1; then
    list="$(boot_run_with_timeout pacman -Qu 2>/dev/null || true)"
    total="$(printf '%s\n' "$list" | awk 'NF {count++} END {print count+0}')"
  fi

  printf '%s %s\n' "${total:-0}" "${security:-0}"
}

boot_collect_reboot_required() {
  if [[ -f /var/run/reboot-required || -f /run/reboot-required ]]; then
    printf 'true\n'
  else
    printf 'false\n'
  fi
}

boot_collect_failed_services() {
  if ! command -v systemctl >/dev/null 2>&1; then
    printf '[]\n'
    return
  fi
  boot_run_with_timeout systemctl --failed --no-legend --plain 2>/dev/null \
    | awk '{print $1}' \
    | sed '/^$/d' \
    | python3 -c 'import json,sys; print(json.dumps([line.strip() for line in sys.stdin if line.strip()]))' 2>/dev/null \
    || printf '[]\n'
}

boot_collect_network_lan() {
  local lan=""
  if command -v hostname >/dev/null 2>&1; then
    lan="$(boot_run_with_timeout hostname -I 2>/dev/null | awk '{print $1}' || true)"
  fi
  if [[ -z "$lan" ]] && command -v ip >/dev/null 2>&1; then
    lan="$(boot_run_with_timeout ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}' || true)"
  fi
  printf '%s\n' "$lan"
}
