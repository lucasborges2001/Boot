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

render_temps_detail() {
  # args: temp_cpu_max temp_sev groups_html
  local temp_cpu="$1" temp_sev="$2" groups_html="$3"

  cat <<HTML
<b>🌡 Temperaturas (detalle)</b>

• CPU Package (máx): <b>${temp_cpu:-n/a}°C</b> $(render_icon "$temp_sev") <b>${temp_sev}</b>

${groups_html}
HTML
}

_render_trim_lines() {
  # args: max_lines
  local max_lines="$1"
  awk -v n="$max_lines" 'NR<=n{print}'
}

render_updates_detail() {
  # args: security_list regular_list held_list
  local sec_list="$1" reg_list="$2" held_list="$3"

  local sec_n reg_n held_n
  sec_n=$(grep -c . <<<"$sec_list" 2>/dev/null || echo 0)
  reg_n=$(grep -c . <<<"$reg_list" 2>/dev/null || echo 0)
  held_n=$(grep -c . <<<"$held_list" 2>/dev/null || echo 0)

  local TOPN=15

  echo "<b>📦 Updates (detalle)</b>"
  echo ""
  echo "• Security: <b>${sec_n}</b>"
  if [[ "$sec_n" -gt 0 ]]; then
    echo "<pre>$(printf '%s\n' "$sec_list" | _render_trim_lines "$TOPN")</pre>"
  else
    echo "<pre>(none)</pre>"
  fi

  echo "• Updates: <b>${reg_n}</b>"
  if [[ "$reg_n" -gt 0 ]]; then
    echo "<pre>$(printf '%s\n' "$reg_list" | _render_trim_lines "$TOPN")</pre>"
  else
    echo "<pre>(none)</pre>"
  fi

  echo "• Held: <b>${held_n}</b>"
  if [[ "$held_n" -gt 0 ]]; then
    echo "<pre>$(printf '%s\n' "$held_list" | _render_trim_lines "$TOPN")</pre>"
  else
    echo "<pre>(none)</pre>"
  fi

  echo "<i>Tip:</i> para ver detalle de versiones/origen: <code>apt-get -s upgrade</code>"
}

render_failed_detail() {
  # args: failed_list
  local failed_list="$1"
  local n
  n=$(grep -c . <<<"$failed_list" 2>/dev/null || echo 0)

  echo "<b>🧩 Servicios / Failed units</b>"
  echo ""

  if [[ "$n" -eq 0 ]]; then
    echo "✅ No failed units"
    return 0
  fi

  echo "• Failed: <b>${n}</b>"
  echo "<pre>$(printf '%s\n' "$failed_list")</pre>"
  echo "<b>Diagnóstico</b>"
  echo "• <code>systemctl status &lt;unit&gt; --no-pager</code>"
  echo "• <code>journalctl -u &lt;unit&gt; -b --no-pager -n 200</code>"
  echo "• <code>systemctl restart &lt;unit&gt;</code> (si aplica)"
}

render_update_howto() {
  cat <<'HTML'
<b>🛠️ Actualizar (guía)</b>

<b>Modo seguro (recomendado)</b>
• <code>sudo apt update</code> — refresca índices
• <code>apt list --upgradable</code> — lista paquetes
• <code>sudo apt upgrade</code> — actualiza sin cambios agresivos

<b>Modo completo</b>
• <code>sudo apt full-upgrade</code> — permite cambios de dependencias

<b>Limpieza</b>
• <code>sudo apt autoremove</code> — borra huérfanos
• <code>sudo apt autoclean</code> — limpia cache parcial

<b>Reboot (solo si corresponde)</b>
• <code>test -f /var/run/reboot-required && echo "Reboot recomendado"</code>
HTML
}

render_buttons_json() {
  # args: temps_url updates_url failed_url howto_url
  local temps_url="$1" updates_url="$2" failed_url="$3" howto_url="$4"

  # JSON compacto, sin jq
  cat <<JSON
{"inline_keyboard":[
  [{"text":"🌡 Temperaturas","url":"${temps_url}"},{"text":"📦 Updates","url":"${updates_url}"}],
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
  local alerts="$1"
  
  if [[ -z "$alerts" ]]; then
    return 0
  fi
  
  cat <<HTML
<b>🚨 PROBLEMAS DETECTADOS</b>
<pre>${alerts}</pre>

HTML
}

render_summary() {
  # args:
  # 1 label 2 host 3 ip_lan 4 ip_wan 5 kernel 6 uptime 7 date
  # 8 load_pct 9 load_sev 10 ram_pct 11 ram_sev 12 disk_pct 13 disk_sev 14 temp_cpu 15 temp_sev
  # 16 updates_count 17 failed_count 18 warn_load 19 crit_load 20 warn_ram 21 crit_ram 22 warn_disk 23 crit_disk 24 warn_temp 25 crit_temp
  # 26 load_trend 27 ram_trend 28 disk_trend

  local label="$1" host="$2" ip_lan="$3" ip_wan="$4" kernel="$5" uptime="$6" date="$7"
  local load_pct="$8" load_sev="$9" ram_pct="${10}" ram_sev="${11}" disk_pct="${12}" disk_sev="${13}"
  local temp_cpu="${14}" temp_sev="${15}" updates_count="${16}" failed_count="${17}"
  local warn_load="${18}" crit_load="${19}" warn_ram="${20}" crit_ram="${21}"
  local warn_disk="${22}" crit_disk="${23}" warn_temp="${24}" crit_temp="${25}"
  local load_trend="${26}" ram_trend="${27}" disk_trend="${28}"

  local SLABEL HOST_ESC
  SLABEL="$(tg_escape_html "$label")"
  HOST_ESC="$(tg_escape_html "$host")"

  # Calcular proximidad a límites
  local load_prox ram_prox disk_prox temp_prox
  load_prox=$(awk -v c="$load_pct" -v l="$crit_load" 'BEGIN{printf "%d", (c/l)*100}')
  ram_prox=$(awk -v c="$ram_pct" -v l="$crit_ram" 'BEGIN{printf "%d", (c/l)*100}')
  disk_prox=$(awk -v c="$disk_pct" -v l="$crit_disk" 'BEGIN{printf "%d", (c/l)*100}')
  
  local load_warn_txt ram_warn_txt disk_warn_txt temp_warn_txt
  [[ "$load_prox" -ge 80 ]] && load_warn_txt=" ⚠️ ${load_prox}% del máx" || load_warn_txt=""
  [[ "$ram_prox" -ge 80 ]] && ram_warn_txt=" ⚠️ ${ram_prox}% del máx" || ram_warn_txt=""
  [[ "$disk_prox" -ge 80 ]] && disk_warn_txt=" ⚠️ ${disk_prox}% del máx" || disk_warn_txt=""
  
  if [[ -n "$temp_cpu" && "$temp_sev" != "NA" ]]; then
    temp_prox=$(awk -v c="$temp_cpu" -v l="$crit_temp" 'BEGIN{printf "%d", (c/l)*100}')
    [[ "$temp_prox" -ge 80 ]] && temp_warn_txt=" ⚠️ ${temp_prox}% del máx" || temp_warn_txt=""
  else
    temp_warn_txt=""
  fi

  cat <<HTML
<b>DAILY REPORT</b>
🏷️ <b>${SLABEL}</b>
🖥️ ${HOST_ESC}
🌐 LAN: <code>${ip_lan:-?}</code>
🌍 WAN: <code>${ip_wan:-?}</code>
🧠 Kernel: <code>${kernel}</code>
⏱️ Uptime: ${uptime}
🕒 ${date}

<pre>$(render_icon "$load_sev") Load : ${load_pct}% (${load_sev})${load_warn_txt} ${load_trend}
$(render_icon "$ram_sev") RAM  : ${ram_pct}% (${ram_sev})${ram_warn_txt} ${ram_trend}
$(render_icon "$disk_sev") Disk : ${disk_pct}% (${disk_sev})${disk_warn_txt} ${disk_trend}
$(render_icon "$temp_sev") Temp : ${temp_cpu:-n/a}°C (${temp_sev})${temp_warn_txt}
📦 Updates: ${updates_count}
🧩 Failed : ${failed_count}</pre>
HTML
}

render_recommendations() {
  # args: load_pct ram_pct disk_pct updates_count upd_sec_n
  local load_pct="$1" ram_pct="$2" disk_pct="$3" updates_count="$4" upd_sec_n="$5"
  local recs=""

  [[ "$load_pct" -gt 80 ]] && recs+="⚠️ Carga alta: revisar procesos con <code>top/htop</code>"$'\n'
  [[ "$ram_pct" -gt 80 ]] && recs+="⚠️ RAM alta: posibles memory leaks, revisar servicios"$'\n'
  [[ "$disk_pct" -gt 80 ]] && recs+="⚠️ Disco casi lleno: limpia logs/datos o amplía volumen"$'\n'
  [[ "$upd_sec_n" -gt 0 ]] && recs+="🔒 ${upd_sec_n} actualizaciones de SEGURIDAD: applica URGENTE"$'\n'
  [[ "$updates_count" -gt 20 ]] && recs+="📦 Muchas actualizaciones pendientes (${updates_count})"$'\n'

  if [[ -n "$recs" ]]; then
    echo "<b>💡 Recomendaciones</b>"
    echo "<pre>$recs</pre>"
  fi
}

render_network_info() {
  # args: network_info_html
  local net_info="$1"
  
  if [[ -z "$net_info" ]]; then
    return 0
  fi
  
  cat <<HTML
<b>🌐 Conectividad</b>
<pre>${net_info}</pre>
HTML
}

render_top_processes() {
  # args: top_cpu top_mem
  local top_cpu="$1" top_mem="$2"
  local cpu_lines mem_lines
  
  cpu_lines=$(echo "$top_cpu" | wc -l)
  mem_lines=$(echo "$top_mem" | wc -l)
  
  if [[ "$cpu_lines" -lt 2 && "$mem_lines" -lt 2 ]]; then
    return 0
  fi
  
  cat <<'HTML'
<b>🔝 Top Procesos</b>
<pre>
CPU (%)
HTML
  
  echo "$top_cpu" | awk '{printf "• %s (%s): %.1f%%\n", $1, $2, $3}'
  
  cat <<'HTML'

RAM (%)
HTML
  
  echo "$top_mem" | awk '{printf "• %s (%s): %.1f%%\n", $1, $2, $3}'
  
  cat <<'HTML'
</pre>
HTML
}

render_disk_health() {
  # args: smartctl_status
  local status="$1"
  
  if [[ "$status" == "UNKNOWN" ]]; then
    return 0
  fi
  
  local icon msg
  case "$status" in
    PASS) icon="✅"; msg="Disco OK (SMART PASS)" ;;
    FAIL) icon="🔴"; msg="<b>Disco con problemas (SMART FAIL)</b> - Considera backup urgente" ;;
    *) return 0 ;;
  esac
  
  echo "<b>💾 Salud del Disco</b>"
  echo "${icon} ${msg}"
}

render_service_changes() {
  # args: service_changes_text
  local changes="$1"
  
  if [[ -z "$changes" ]]; then
    return 0
  fi
  
  cat <<HTML
<b>🔄 Cambios de Servicios</b>
<pre>${changes}</pre>
HTML
}

render_security_banner() {
  # args: upd_sec_n
  local sec_n="$1"
  
  if [[ "$sec_n" -lt 1 ]]; then
    return 0
  fi
  
  cat <<HTML
<b>🔒 ACTUALIZACIÓN DE SEGURIDAD DISPONIBLE</b>
<i>${sec_n} paquete(s) de seguridad pendiente(s). Aplica cuanto antes.</i>

HTML
}

