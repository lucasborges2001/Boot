#!/usr/bin/env bash
# Procesos legacy para Boot.

sys_top_processes() {
  local metric="$1" count="${2:-5}"
  if [[ "$metric" == "cpu" ]]; then
    ps aux --sort=-%cpu | awk -v n="$count" 'NR>1 && NR<=n+1 {cmd=$11; sub(".*/","",cmd); printf "%s %s %.1f\n", cmd, $2, $3}'
  elif [[ "$metric" == "mem" ]]; then
    ps aux --sort=-%mem | awk -v n="$count" 'NR>1 && NR<=n+1 {cmd=$11; sub(".*/","",cmd); printf "%s %s %.1f\n", cmd, $2, $4}'
  fi
}
