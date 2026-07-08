#!/usr/bin/env bash
# Resumen principal legacy de Telegram Boot.

render_summary() {
  local label="$1" host="$2" ip_lan="$3" ip_wan="$4" kernel="$5" uptime="$6" date="$7"
  local load_pct="$8" load_sev="$9" ram_pct="${10}" ram_sev="${11}" disk_pct="${12}" disk_sev="${13}"
  local temp_cpu="${14}" temp_sev="${15}" updates_count="${16}" upd_sec_n="${17}" failed_count="${18}"
  local load_trend="${27}" ram_trend="${28}" disk_trend="${29}"

  local SLABEL HOST_ESC
  SLABEL="$(tg_escape_html "$label")"
  HOST_ESC="$(tg_escape_html "$host")"

  local services_icon updates_icon
  if [[ "$failed_count" -gt 0 ]]; then services_icon="🔴"; else services_icon="🟢"; fi

  if [[ "$upd_sec_n" -gt 0 ]]; then
    updates_icon="🔴"
  elif [[ "$updates_count" -gt 0 ]]; then
    updates_icon="🟠"
  else
    updates_icon="🟢"
  fi

  echo "<b>REPORTE DIARIO</b>"
  echo "🏷️ <b>${SLABEL}</b>  |  🖥️ ${HOST_ESC}"
  echo "🕒 ${date}"
  echo ""
  echo "<b>Estado</b>"
  echo "$(render_icon "$load_sev") ⚙️ <b>Carga:</b> ${load_pct}% — <b>$(render_sev_label "$load_sev")</b>$(render_trend "$load_trend")"
  echo "$(render_icon "$ram_sev") 🧠 <b>Memoria:</b> ${ram_pct}% — <b>$(render_sev_label "$ram_sev")</b>$(render_trend "$ram_trend")"
  echo "$(render_icon "$disk_sev") 💾 <b>Disco:</b> ${disk_pct}% — <b>$(render_sev_label "$disk_sev")</b>$(render_trend "$disk_trend")"

  if [[ -n "$temp_cpu" && "$temp_sev" != "NA" ]]; then
    echo "$(render_icon "$temp_sev") 🌡️ <b>Temp:</b> ${temp_cpu}°C — <b>$(render_sev_label "$temp_sev")</b>"
  else
    echo "⚪ 🌡️ <b>Temp:</b> — — <b>N/D</b>"
  fi

  echo "${updates_icon} 📦 <b>Actualizaciones:</b> ${updates_count} (🔒 ${upd_sec_n})"
  echo "${services_icon} 🧩 <b>Servicios fallidos:</b> ${failed_count}"
  echo ""
  echo "<b>Red & sistema</b>"
  echo "🌐 <b>LAN:</b> ${ip_lan:-—}"
  echo "🌍 <b>WAN:</b> ${ip_wan:-—}"
  echo "⏱️ <b>Uptime:</b> ${uptime}"
  echo "🧩 <b>Kernel:</b> ${kernel}"
}
