#!/usr/bin/env bash
# Bloques de detalle para Telegram legacy de Boot.

render_temps_detail() {
  local temp_cpu="$1" temp_sev="$2" groups_html="$3"

  cat <<HTML
<b>🌡 Temperaturas</b>

• <b>CPU (máx):</b> <b>${temp_cpu:-—}°C</b> $(render_icon "$temp_sev") <b>$(render_sev_label "$temp_sev")</b>

${groups_html}
HTML
}

render_updates_detail() {
  local sec_list="$1" reg_list="$2" held_list="$3"

  local sec_n reg_n held_n total_n
  sec_n=$(grep -c . <<<"$sec_list" 2>/dev/null || true)
  reg_n=$(grep -c . <<<"$reg_list" 2>/dev/null || true)
  held_n=$(grep -c . <<<"$held_list" 2>/dev/null || true)
  total_n=$((sec_n + reg_n + held_n))

  echo "<b>📦 Actualizaciones</b>"
  echo ""

  if [[ "$total_n" -eq 0 ]]; then
    echo "✅ No hay actualizaciones pendientes."
    return 0
  fi

  if [[ "$sec_n" -gt 0 ]]; then
    echo "🔒 <b>Seguridad:</b> ${sec_n}"
    _render_bullets "$sec_list" 15
    echo ""
  fi

  if [[ "$reg_n" -gt 0 ]]; then
    echo "📦 <b>Normales:</b> ${reg_n}"
    _render_bullets "$reg_list" 15
    echo ""
  fi

  if [[ "$held_n" -gt 0 ]]; then
    echo "⏸️ <b>En hold:</b> ${held_n}"
    _render_bullets "$held_list" 15
  fi
}

render_services_detail() {
  local failed_list="$1"
  local changes="$2"
  local n
  n=$(grep -c . <<<"$failed_list" 2>/dev/null || true)

  echo "<b>🧩 Servicios</b>"
  echo ""

  if [[ "$n" -eq 0 && -z "$changes" ]]; then
    echo "✅ Sin servicios fallidos."
    return 0
  fi

  if [[ -n "$changes" ]]; then
    echo "🔄 <b>Cambios desde el último reporte</b>"
    _render_bullets "$changes" 25
    echo ""
  fi

  if [[ "$n" -gt 0 ]]; then
    echo "❌ <b>Servicios fallidos:</b> ${n}"
    _render_bullets "$failed_list" 30
    echo ""
    echo "🩺 <b>Diagnóstico</b>"
    echo "• systemctl status <i>&lt;unit&gt;</i> --no-pager"
    echo "• journalctl -u <i>&lt;unit&gt;</i> -b --no-pager -n 200"
    echo "• systemctl restart <i>&lt;unit&gt;</i>"
  fi
}

render_update_howto() {
  cat <<'HTML'
<b>🛠️ Actualizar (guía)</b>

<b>Modo seguro (recomendado)</b>
• apt update — refresca índices (con privilegios)
• apt list --upgradable — lista paquetes
• apt upgrade — actualiza sin cambios agresivos (con privilegios)

<b>Modo completo</b>
• apt full-upgrade — permite cambios de dependencias (con privilegios)

<b>Limpieza</b>
• apt autoremove — borra huérfanos (con privilegios)
• apt autoclean — limpia cache parcial (con privilegios)

<b>Reinicio</b>
• test -f /var/run/reboot-required && echo "Reinicio recomendado"
HTML
}
