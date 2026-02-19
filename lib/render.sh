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

render_summary() {
  # args:
  # 1 label 2 host 3 ip_lan 4 ip_wan 5 kernel 6 uptime 7 date
  # 8 load_pct 9 load_sev 10 ram_pct 11 ram_sev 12 disk_pct 13 disk_sev 14 temp_cpu 15 temp_sev
  # 16 updates_count 17 failed_count

  local label="$1" host="$2" ip_lan="$3" ip_wan="$4" kernel="$5" uptime="$6" date="$7"
  local load_pct="$8" load_sev="$9" ram_pct="${10}" ram_sev="${11}" disk_pct="${12}" disk_sev="${13}"
  local temp_cpu="${14}" temp_sev="${15}" updates_count="${16}" failed_count="${17}"

  local SLABEL HOST_ESC
  SLABEL="$(tg_escape_html "$label")"
  HOST_ESC="$(tg_escape_html "$host")"

  cat <<HTML
<b>DAILY REPORT</b>
🏷️ <b>${SLABEL}</b>
🖥️ ${HOST_ESC}
🌐 LAN: <code>${ip_lan:-?}</code>
🌍 WAN: <code>${ip_wan:-?}</code>
🧠 Kernel: <code>${kernel}</code>
⏱️ Uptime: ${uptime}
🕒 ${date}

<pre>$(render_icon "$load_sev") Load : ${load_pct}% (${load_sev})
$(render_icon "$ram_sev") RAM  : ${ram_pct}% (${ram_sev})
$(render_icon "$disk_sev") Disk : ${disk_pct}% (${disk_sev})
$(render_icon "$temp_sev") Temp : ${temp_cpu:-n/a}°C (${temp_sev})
📦 Updates: ${updates_count}
🧩 Failed : ${failed_count}</pre>
HTML
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
