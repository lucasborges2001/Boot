#!/usr/bin/env bash
set -euo pipefail

# lib/render.sh
# Responsabilidad única: armar textos HTML (Telegram) y JSON de botones.

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
  # Mapea códigos internos a etiquetas en español (sin tocar lógica).
  local sev="$1"
  case "$sev" in
    CRIT) echo "CRÍTICO" ;;
    WARN) echo "AVISO" ;;
    OK)   echo "OK" ;;
    NA)   echo "N/D" ;;
    *)    echo "N/D" ;;
  esac
}

render_temps_detail() {
  # args: temp_cpu_max temp_sev groups_html
  local temp_cpu="$1" temp_sev="$2" groups_html="$3"

  cat <<HTML
<b>🌡 Temperaturas</b>

• <b>CPU (máx):</b> <b>${temp_cpu:-—}°C</b> $(render_icon "$temp_sev") <b>$(render_sev_label "$temp_sev")</b>

${groups_html}
HTML
}


render_trend() {
  # args: trend_string (ej: "↗ +5", "↘ -2", "→ 0")
  local t="${1:-}"
  [[ -z "$t" ]] && { echo ""; return; }
  # ocultar cuando no hay cambio
  if [[ "$t" =~ ^→[[:space:]]*\+?0$ ]]; then
    echo ""
    return 0
  fi
  echo " ${t}"
}

_render_trim_lines() {
  # args: max_lines
  local max_lines="$1"
  awk -v n="$max_lines" 'NR<=n{print}'
}

_render_bullets() {
  # args: text max_lines (imprime bullets HTML, sin <pre>)
  local text="${1:-}" max_lines="${2:-30}"
  [[ -z "$text" ]] && return 0
  printf '%s\n' "$text" | _render_trim_lines "$max_lines" | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    echo "• $(tg_escape_html "$line")"
  done
}


render_updates_detail() {
  # args: security_list regular_list held_list
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
  # args: failed_list service_changes
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
• sudo apt update — refresca índices
• apt list --upgradable — lista paquetes
• sudo apt upgrade — actualiza sin cambios agresivos

<b>Modo completo</b>
• sudo apt full-upgrade — permite cambios de dependencias

<b>Limpieza</b>
• sudo apt autoremove — borra huérfanos
• sudo apt autoclean — limpia cache parcial

<b>Reinicio</b>
• test -f /var/run/reboot-required && echo "Reinicio recomendado"
HTML
}


render_buttons_json() {
  # args: temps_url updates_url failed_url howto_url
  local temps_url="$1" updates_url="$2" failed_url="$3" howto_url="$4"

  # JSON compacto, sin jq
  cat <<JSON
{"inline_keyboard":[
  [{"text":"🌡 Temperaturas","url":"${temps_url}"},{"text":"📦 Actualizaciones","url":"${updates_url}"}],
  [{"text":"🧩 Servicios","url":"${failed_url}"},{"text":"🛠️ Actualizar","url":"${howto_url}"}]
]}
JSON
}

# --- Mejoras: Indicadores, alertas, recomendaciones ---

render_proximity_indicator() {
  # args: value limit
  # Retorna: emoji/indicador de proximidad
  local val="$1" limit="$2"
  local pct
  pct=$(awk -v c="$val" -v l="$limit" 'BEGIN{printf "%d", (c/l)*100}')
  
  if [[ "$pct" -ge 95 ]]; then echo "🔴 CRÍTICO"; return; fi
  if [[ "$pct" -ge 80 ]]; then echo "🟠 CERCA"; return; fi
  echo "🟢 OK"
}

render_critical_banner() {
  # args: alerts_text (puede estar vacío)
  local alerts="${1:-}"

  [[ -z "$alerts" ]] && return 0

  echo "<b>🚨 ALERTAS</b>"
  printf '%s\n' "$alerts" | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # alerts ya viene con "• ..." desde boot-report.sh; solo escapamos
    echo "$(tg_escape_html "$line")"
  done
  echo ""
}


render_summary() {
  # args:
  # 1 label 2 host 3 ip_lan 4 ip_wan 5 kernel 6 uptime 7 date
  # 8 load_pct 9 load_sev 10 ram_pct 11 ram_sev 12 disk_pct 13 disk_sev 14 temp_cpu 15 temp_sev
  # 16 updates_count 17 upd_sec_n 18 failed_count 19 warn_load 20 crit_load 21 warn_ram 22 crit_ram 23 warn_disk 24 crit_disk 25 warn_temp 26 crit_temp
  # 27 load_trend 28 ram_trend 29 disk_trend

  local label="$1" host="$2" ip_lan="$3" ip_wan="$4" kernel="$5" uptime="$6" date="$7"
  local load_pct="$8" load_sev="$9" ram_pct="${10}" ram_sev="${11}" disk_pct="${12}" disk_sev="${13}"
  local temp_cpu="${14}" temp_sev="${15}" updates_count="${16}" upd_sec_n="${17}" failed_count="${18}"
  local load_trend="${27}" ram_trend="${28}" disk_trend="${29}"

  local SLABEL HOST_ESC
  SLABEL="$(tg_escape_html "$label")"
  HOST_ESC="$(tg_escape_html "$host")"

  # Iconos derivados
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


render_recommendations() {
  # args: load_pct ram_pct disk_pct updates_count upd_sec_n
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


render_network_info() {
  # args: network_info_text
  local net_info="${1:-}"

  [[ -z "$net_info" ]] && return 0

  echo "<b>🌐 Conectividad</b>"
  echo ""
  _render_bullets "$net_info" 80
}


render_top_processes() {
  # args: top_cpu top_mem
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
  # args: smartctl_status
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
  # args: service_changes_text
  local changes="$1"

  [[ -z "$changes" ]] && return 0

  echo "<b>🔄 Cambios de Servicios</b>"
  echo ""
  _render_bullets "$changes" 30
}


render_security_banner() {
  # args: upd_sec_n
  local sec_n="$1"
  
  if [[ "$sec_n" -lt 1 ]]; then
    return 0
  fi
  
  cat <<HTML
<b>🔒 ACTUALIZACIÓN DE SEGURIDAD DISPONIBLE</b>
<i>${sec_n} paquete(s) de seguridad pendiente(s). Aplicar cuanto antes.</i>

HTML
}