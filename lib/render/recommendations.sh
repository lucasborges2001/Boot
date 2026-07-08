#!/usr/bin/env bash
# Recomendaciones y banners legacy de Boot.

render_critical_banner() {
  local alerts="${1:-}"

  [[ -z "$alerts" ]] && return 0

  echo "<b>🚨 ALERTAS</b>"
  printf '%s\n' "$alerts" | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    echo "$(tg_escape_html "$line")"
  done
  echo ""
}

render_recommendations() {
  local load_pct="$1" ram_pct="$2" disk_pct="$3" updates_count="$4" upd_sec_n="$5"
  local recs=""

  [[ "$load_pct" -gt 80 ]] && recs+="Carga alta: revisar procesos (top/htop)"$'\n'
  [[ "$ram_pct" -gt 80 ]] && recs+="RAM alta: revisar servicios / posibles leaks"$'\n'
  [[ "$disk_pct" -gt 80 ]] && recs+="Disco casi lleno: limpiar logs/datos o ampliar volumen"$'\n'
  [[ "$upd_sec_n" -gt 0 ]] && recs+="${upd_sec_n} actualizaciones de SEGURIDAD: aplicar cuanto antes"$'\n'
  [[ "$updates_count" -gt 20 ]] && recs+="Muchas actualizaciones pendientes (${updates_count})"$'\n'

  [[ -z "$recs" ]] && return 0

  echo "<b>💡 Recomendaciones</b>"
  echo ""
  _render_bullets "$recs" 20
}

render_security_banner() {
  local sec_n="$1"

  if [[ "$sec_n" -lt 1 ]]; then
    return 0
  fi

  cat <<HTML
<b>🔒 ACTUALIZACIÓN DE SEGURIDAD DISPONIBLE</b>
<i>${sec_n} paquete(s) de seguridad pendiente(s). Aplicar cuanto antes.</i>

HTML
}
