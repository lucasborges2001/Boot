#!/usr/bin/env bash
# Servicios legacy para Boot.

sys_failed_units_list() {
  systemctl --failed --no-legend 2>/dev/null | awk '{print $1}'
}

sys_service_changes() {
  local statefile="/var/lib/boot-report/last_services"
  local current_list

  if ! command -v systemctl >/dev/null 2>&1; then
    return 0
  fi

  current_list="$(systemctl list-units --type=service --no-legend --all 2>/dev/null | awk '{print $1":"$3}' | sort || true)"

  mkdir -p "$(dirname "$statefile")" 2>/dev/null || true

  if [[ ! -f "$statefile" ]]; then
    echo "$current_list" > "$statefile" 2>/dev/null || true
    return 0
  fi

  local prev_list
  prev_list="$(cat "$statefile" 2>/dev/null || true)"

  local changes=""
  while read -r line; do
    [[ -z "$line" ]] && continue
    if ! echo "$prev_list" | grep -q "^$line$"; then
      local svc="${line%:*}"
      changes+="INICIADO: $(basename "$svc")"$'\n'
    fi
  done <<<"$current_list"

  while read -r line; do
    [[ -z "$line" ]] && continue
    if ! echo "$current_list" | grep -q "^$line$"; then
      local svc="${line%:*}"
      changes+="DETENIDO: $(basename "$svc")"$'\n'
    fi
  done <<<"$prev_list"

  echo -e "$changes"
  echo "$current_list" > "$statefile" 2>/dev/null || true
}
