#!/usr/bin/env bash
# Diagnóstico adicional legacy de Boot.

render_network_info() {
  local net_info="${1:-}"

  [[ -z "$net_info" ]] && return 0

  echo "<b>🌐 Conectividad</b>"
  echo ""
  _render_bullets "$net_info" 80
}

render_top_processes() {
  local top_cpu="$1" top_mem="$2"

  local cpu_lines mem_lines
  cpu_lines=$(grep -c . <<<"$top_cpu" 2>/dev/null || echo 0)
  mem_lines=$(grep -c . <<<"$top_mem" 2>/dev/null || echo 0)

  if [[ "$cpu_lines" -lt 1 && "$mem_lines" -lt 1 ]]; then
    return 0
  fi

  echo "<b>🔝 Procesos principales</b>"
  echo ""

  if [[ "$cpu_lines" -gt 0 ]]; then
    echo "🔥 <b>CPU</b>"
    printf '%s\n' "$top_cpu" | _render_trim_lines 8 | while read -r name pid pct; do
      [[ -z "$name" ]] && continue
      echo "• ${name} (pid ${pid}): ${pct}%"
    done
    echo ""
  fi

  if [[ "$mem_lines" -gt 0 ]]; then
    echo "🧠 <b>RAM</b>"
    printf '%s\n' "$top_mem" | _render_trim_lines 8 | while read -r name pid pct; do
      [[ -z "$name" ]] && continue
      echo "• ${name} (pid ${pid}): ${pct}%"
    done
  fi
}

render_disk_health() {
  local status="$1"

  local icon msg
  case "$status" in
    FAIL) icon="🔴"; msg="<b>SMART FAIL</b> — tomar backup urgente" ;;
    *) return 0 ;;
  esac

  echo "<b>💾 Salud del Disco</b>"
  echo "${icon} ${msg}"
}

render_service_changes() {
  local changes="$1"

  [[ -z "$changes" ]] && return 0

  echo "<b>🔄 Cambios de Servicios</b>"
  echo ""
  _render_bullets "$changes" 30
}
