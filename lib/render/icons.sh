#!/usr/bin/env bash
# Iconos, etiquetas y tendencias para render legacy de Boot.

render_icon() {
  local sev="$1"
  local emoji="${BOOT_EMOJI:-true}"
  [[ "$emoji" != "true" ]] && { echo ""; return; }
  case "$sev" in
    CRIT) echo "🔴" ;;
    WARN) echo "🟠" ;;
    OK)   echo "🟢" ;;
    NA)   echo "⚪" ;;
    *)    echo "⚪" ;;
  esac
}

render_sev_label() {
  local sev="$1"
  case "$sev" in
    CRIT) echo "CRÍTICO" ;;
    WARN) echo "AVISO" ;;
    OK)   echo "OK" ;;
    NA)   echo "N/D" ;;
    *)    echo "N/D" ;;
  esac
}

render_trend() {
  local t="${1:-}"
  [[ -z "$t" ]] && { echo ""; return; }
  if [[ "$t" =~ ^→[[:space:]]*\+?0$ ]]; then
    echo ""
    return 0
  fi
  echo " ${t}"
}

render_proximity_indicator() {
  local val="$1" limit="$2"
  local pct
  pct=$(awk -v c="$val" -v l="$limit" 'BEGIN{printf "%d", (c/l)*100}')

  if [[ "$pct" -ge 95 ]]; then echo "🔴 CRÍTICO"; return; fi
  if [[ "$pct" -ge 80 ]]; then echo "🟠 CERCA"; return; fi
  echo "🟢 OK"
}
