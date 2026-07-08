#!/usr/bin/env bash
# Alertas, proximidad y tendencias legacy para Boot.

sys_pct_proximity_to_limit() {
  local current="$1" limit="$2"
  if [[ "$current" -ge "$limit" ]]; then
    echo "100"
  else
    awk -v c="$current" -v l="$limit" 'BEGIN{printf "%d", (c/l)*100}'
  fi
}

sys_critical_alerts() {
  local load_sev="$1" ram_sev="$2" disk_sev="$3" temp_sev="$4" failed_count="$5" upd_sec_n="$6"
  local alerts=""

  [[ "$load_sev" == "CRIT" ]] && alerts+="• Load crítica"$'\n'
  [[ "$ram_sev" == "CRIT" ]] && alerts+="• RAM crítica"$'\n'
  [[ "$disk_sev" == "CRIT" ]] && alerts+="• Disco crítico"$'\n'
  [[ "$temp_sev" == "CRIT" ]] && alerts+="• Temperatura crítica"$'\n'
  [[ "$failed_count" -gt 0 ]] && alerts+="• $failed_count servicios fallidos"$'\n'
  [[ "$upd_sec_n" -gt 0 ]] && alerts+="• $upd_sec_n actualizaciones de SEGURIDAD"$'\n'

  echo -e "$alerts"
}

sys_metric_trend() {
  local current="$1" metric="$2"
  local statefile="/var/lib/boot-report/last_${metric}"

  mkdir -p "$(dirname "$statefile")" 2>/dev/null || true

  if [[ ! -f "$statefile" ]]; then
    echo "$current" > "$statefile" 2>/dev/null || true
    echo "→ 0"
    return 0
  fi

  local prev
  prev="$(cat "$statefile" 2>/dev/null || echo "$current")"

  local diff
  diff=$((current - prev))

  local direction
  if [[ "$diff" -gt 0 ]]; then
    direction="↗"
  elif [[ "$diff" -lt 0 ]]; then
    direction="↘"
  else
    direction="→"
  fi

  echo "$current" > "$statefile" 2>/dev/null || true
  echo "$direction $(printf '%+d' "$diff")"
}
