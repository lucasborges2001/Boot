#!/usr/bin/env bash
# Boot report orchestration. Generic env/json/log/time helpers come from Base.

if [[ -n "${BOOT_COLLECT_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_COLLECT_SH_INCLUDED=1

BOOT_COLLECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOT_PYTHON_DIR="$(cd "$BOOT_COLLECT_DIR/../python" && pwd)"
source "$BOOT_COLLECT_DIR/collect/system.sh"
source "$BOOT_COLLECT_DIR/collect/cpu.sh"
source "$BOOT_COLLECT_DIR/collect/memory.sh"
source "$BOOT_COLLECT_DIR/collect/storage.sh"
source "$BOOT_COLLECT_DIR/collect/network.sh"

boot_collect_memory() {
  boot_collect_memory_json | python3 -c 'import json,sys; value=json.load(sys.stdin).get("used_percent"); print(0 if value is None else value)'
}

boot_collect_disk() {
  boot_collect_filesystems_json | python3 -c 'import json,sys; items=json.load(sys.stdin); root=next((item for item in items if item.get("mount")=="/"), {}); value=root.get("used_percent"); print(0 if value is None else value)'
}

boot_collect_network() {
  boot_collect_network_lan
}

boot_collect_report_json() {
  command -v python3 >/dev/null 2>&1 || { echo "python3 is required to generate Boot report JSON" >&2; return 127; }

  local generated_at hostname kernel uptime load1 load5 load15 temperature updates_total updates_security
  local reboot_required failed_json ip_lan reports_dir cpu_json memory_json filesystems_json disk_io_json network_json

  generated_at="$(boot_collect_generated_at)"
  hostname="$(boot_collect_hostname)"
  kernel="$(boot_collect_kernel)"
  uptime="$(boot_collect_uptime)"
  read -r load1 load5 load15 <<<"$(boot_collect_load)"
  temperature="$(boot_collect_temperature)"
  read -r updates_total updates_security <<<"$(boot_collect_updates)"
  reboot_required="$(boot_collect_reboot_required)"
  failed_json="$(boot_collect_failed_services)"
  reports_dir="${BOOT_REPORTS_DIR:-/var/lib/boot-report/reports}"

  ip_lan=""
  case "${BOOT_INCLUDE_LAN_IP:-true}" in
    1|true|TRUE|yes|YES|on|ON|enabled|ENABLED) ip_lan="$(boot_collect_network_lan)" ;;
  esac

  cpu_json="$(boot_collect_cpu_json)"
  memory_json="$(boot_collect_memory_json)"
  filesystems_json="$(boot_collect_filesystems_json)"
  disk_io_json="$(boot_collect_disk_io_json)"
  network_json="$(boot_collect_network_interfaces_json "$generated_at" "$uptime")"

  BOOT_HOSTNAME_VALUE="$hostname" \
  BOOT_KERNEL_VALUE="$kernel" \
  BOOT_UPTIME_VALUE="${uptime:-0}" \
  BOOT_LOAD_1_VALUE="${load1:-0}" \
  BOOT_LOAD_5_VALUE="${load5:-0}" \
  BOOT_LOAD_15_VALUE="${load15:-0}" \
  BOOT_TEMPERATURE_VALUE="${temperature:-null}" \
  BOOT_UPDATES_TOTAL_VALUE="${updates_total:-0}" \
  BOOT_UPDATES_SECURITY_VALUE="${updates_security:-0}" \
  BOOT_REBOOT_REQUIRED_VALUE="${reboot_required:-false}" \
  BOOT_FAILED_SERVICES_VALUE="${failed_json:-[]}" \
  BOOT_IP_LAN_VALUE="$ip_lan" \
  BOOT_GENERATED_AT_VALUE="$generated_at" \
  BOOT_REPORTS_DIR_VALUE="$reports_dir" \
  BOOT_TELEGRAM_ENABLED_VALUE="${BOOT_SEND_TELEGRAM:-true}" \
  BOOT_CPU_JSON="$cpu_json" \
  BOOT_MEMORY_JSON="$memory_json" \
  BOOT_FILESYSTEMS_JSON="$filesystems_json" \
  BOOT_DISK_IO_JSON="$disk_io_json" \
  BOOT_NETWORK_JSON="$network_json" \
  python3 "$BOOT_PYTHON_DIR/build_report.py"
}

boot_report_set_telegram_result() {
  local json="${1:?report json is required}"
  local enabled="${2:-false}"
  local ok="${3:-null}"
  local message_id="${4:-null}"
  local description="${5:-}"

  BOOT_REPORT_JSON="$json" \
  BOOT_TELEGRAM_ENABLED_VALUE="$enabled" \
  BOOT_TELEGRAM_OK_VALUE="$ok" \
  BOOT_TELEGRAM_MESSAGE_ID_VALUE="$message_id" \
  BOOT_TELEGRAM_DESCRIPTION_VALUE="$description" \
  python3 "$BOOT_PYTHON_DIR/set_telegram_result.py"
}
