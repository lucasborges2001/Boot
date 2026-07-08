#!/usr/bin/env bash
# Recolección básica legacy de sistema para Boot.

sys_hostname() {
  hostname -f 2>/dev/null || hostname
}

sys_now() {
  date '+%Y-%m-%d %H:%M:%S %Z'
}

sys_kernel() {
  uname -r
}

sys_uptime_pretty() {
  uptime -p 2>/dev/null || true
}

sys_ip_lan() {
  hostname -I 2>/dev/null | awk '{print $1}'
}

sys_pct_used_mem() {
  local total avail used
  total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
  avail=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
  used=$((total - avail))
  echo $(( used * 100 / total ))
}

sys_root_disk_pct() {
  df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
}

sys_load_pct() {
  local load cpu
  load=$(awk '{print $1}' /proc/loadavg)
  cpu=$(nproc)
  awk -v l="$load" -v c="$cpu" 'BEGIN{printf "%d", (l/c)*100}'
}
