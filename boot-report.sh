#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/opt/boot-report/.env"
set +u
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
set -u

: "${BOT_TOKEN:?Falta BOT_TOKEN en /opt/boot-report/.env}"
: "${CHAT_ID:?Falta CHAT_ID en /opt/boot-report/.env}"

SERVER_LABEL="${SERVER_LABEL:-$(hostname)}"

BOOT_ALERTS_ONLY="${BOOT_ALERTS_ONLY:-false}"
BOOT_EMOJI="${BOOT_EMOJI:-true}"

WARN_LOAD_PCT="${WARN_LOAD_PCT:-70}"
CRIT_LOAD_PCT="${CRIT_LOAD_PCT:-100}"
WARN_RAM_PCT="${WARN_RAM_PCT:-70}"
CRIT_RAM_PCT="${CRIT_RAM_PCT:-85}"
WARN_DISK_PCT="${WARN_DISK_PCT:-70}"
CRIT_DISK_PCT="${CRIT_DISK_PCT:-85}"
WARN_TEMP_C="${WARN_TEMP_C:-70}"
CRIT_TEMP_C="${CRIT_TEMP_C:-85}"

HOST="$(hostname -f 2>/dev/null || hostname)"
DATE="$(date '+%Y-%m-%d %H:%M:%S %Z')"
KERNEL="$(uname -r)"
UPTIME="$(uptime -p 2>/dev/null || true)"

# --- Dedupe DIARIO + lock ---
RUN_DATE="$(date '+%Y-%m-%d')"

RUNDIR="${XDG_RUNTIME_DIR:-/run/boot-report}"
LOCK="${RUNDIR}/lock"

STATEDIR="/var/lib/boot-report"
STAMP="${STATEDIR}/last_run_date"

mkdir -p "$RUNDIR" "$STATEDIR" 2>/dev/null || true

exec 9>"$LOCK" || true
if command -v flock >/dev/null 2>&1; then
  flock -n 9 || exit 0
fi

if [[ -f "$STAMP" ]] && [[ "$(cat "$STAMP" 2>/dev/null || true)" == "$RUN_DATE" ]]; then
  logger -t boot-report "SKIP: ya se ejecutó hoy ($RUN_DATE)"
  exit 0
fi

retry_curl() {
  local tries=5 delay=1 i
  for i in $(seq 1 "$tries"); do
    if "$@"; then return 0; fi
    sleep "$delay"
    delay=$((delay * 2))
  done
  return 1
}

tg_send() {
  local text="$1" resp
  resp="$(retry_curl curl -sS -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"     -d "chat_id=${CHAT_ID}"     -d "parse_mode=HTML"     --data-urlencode "text=${text}"     -d "disable_web_page_preview=true")" || return 1

  echo "$resp" | grep -q '"ok"[[:space:]]*:[[:space:]]*true' || {
    logger -t boot-report "ERROR: telegram sendMessage failed: $resp"
    return 1
  }
}

pct_used_mem() {
  local total avail used
  total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
  avail=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
  used=$((total - avail))
  echo $(( used * 100 / total ))
}

root_disk_pct() {
  df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
}

load_pct() {
  local load cpu
  load=$(awk '{print $1}' /proc/loadavg)
  cpu=$(nproc)
  awk -v l="$load" -v c="$cpu" 'BEGIN{printf "%d", (l/c)*100}'
}

html_escape() {
  # Escapado mínimo para HTML de Telegram
  local s="${1:-}"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  echo "$s"
}

sev() {
  local val="$1" warn="$2" crit="$3"
  if [[ "$val" -ge "$crit" ]]; then echo "CRIT"; return; fi
  if [[ "$val" -ge "$warn" ]]; then echo "WARN"; return; fi
  echo "OK"
}

icon() {
  local s="$1"
  [[ "$BOOT_EMOJI" != "true" ]] && { echo ""; return; }
  case "$s" in
    CRIT) echo "🔴" ;;
    WARN) echo "🟠" ;;
    OK)   echo "🟢" ;;
    NA)   echo "⚪" ;;
    *)    echo "⚪" ;;
  esac
}

cpu_pkg_max_c() {
  # Temperatura máxima de CPU Package (para severidad / thresholds)
  if command -v sensors >/dev/null 2>&1; then
    sensors 2>/dev/null | awk '
      function clean(x){gsub(/[+°C]/,"",x); return x+0}
      /Package id [0-9]+:/ {t=clean($4); if(t>max) max=t}
      END{ if(max>0) print int(max) }
    '
    return 0
  fi

  # Fallback: máximo de thermal zones tipo x86_pkg_temp
  if ls /sys/class/thermal/thermal_zone*/type >/dev/null 2>&1; then
    awk '
      BEGIN{max=-999}
      {
        if ($0 ~ /x86_pkg_temp/) {
          file=FILENAME
          sub(/type$/,"temp",file)
          if ((getline v < file) > 0) {
            t=int(v/1000)
            if (t>max) max=t
          }
          close(file)
        }
      }
      END{ if(max>-999) print max }
    ' /sys/class/thermal/thermal_zone*/type
    return 0
  fi

  echo ""
}

pci_ifname_by_slot() {
  # Busca una interfaz (ej: eth0) por PCI_SLOT_NAME=0000:03:00.0
  local slot="$1" n u
  for n in /sys/class/net/*; do
    [[ -e "$n/device/uevent" ]] || continue
    u="$(cat "$n/device/uevent" 2>/dev/null || true)"
    if echo "$u" | grep -q "PCI_SLOT_NAME=${slot}"; then
      basename "$n"
      return 0
    fi
  done
  return 1
}

tg3_chip_to_slots() {
  # Convierte "tg3-pci-0302" -> candidatos de slot PCI para resolver interfaz.
  # Caso común multi-función: 0302 => 0000:03:00.2 ; 0300 => 0000:03:00.0
  local chip="$1" short bus
  short="${chip#tg3-pci-}"
  bus="${short:0:2}"
  if [[ "$short" =~ ^[0-9]{4}$ ]]; then
    # candidato A: bus + dev00 + func (último dígito)
    echo "0000:${bus}:00.${short:3:1}"
    # candidato B: bus + dev (últimos 2) + func 0
    echo "0000:${bus}:${short:2:2}.0"
  fi
}

cpu_section_html() {
  command -v sensors >/dev/null 2>&1 || return 0
  sensors 2>/dev/null | awk '
    function clean(x){gsub(/[+°C]/,"",x); return x}
    /^[[:alnum:]][[:alnum:]_.:+-]*$/ {chip=$0; curr_pkg=""; next}

    chip ~ /^coretemp-isa-/ && /Package id [0-9]+:/ {
      id=$3; gsub(/:/,"",id)
      t=clean($4)+0
      cpu[id]=t
      if (t>cpu_max) cpu_max=t
      curr_pkg=id
      next
    }

    chip ~ /^coretemp-isa-/ && /^Core [0-9]+:/ {
      if (curr_pkg=="") next
      t=clean($3)+0
      if (!(curr_pkg in coremax) || t>coremax[curr_pkg]) coremax[curr_pkg]=t
      next
    }

    END{
      if (cpu_max<=0) exit
      print "<b>CPU</b>"
      print sprintf("• CPU Package (máx): <b>%d°C</b>", int(cpu_max+0.5))
      for (i=0;i<32;i++) {
        if (i in cpu) {
          line=sprintf("  - Socket %d (Package): <b>%d°C</b>", i, int(cpu[i]+0.5))
          if (i in coremax) line=line sprintf(" (Cores máx %d°C)", int(coremax[i]+0.5))
          print line
        }
      }
    }
  '
}

acpi_section_html() {
  command -v sensors >/dev/null 2>&1 || return 0
  sensors 2>/dev/null | awk '
    function clean(x){gsub(/[+°C]/,"",x); return x}
    /^[[:alnum:]][[:alnum:]_.:+-]*$/ {chip=$0; next}
    chip ~ /^acpitz-acpi-/ && /^temp1:/ {t=clean($2); print "<b>Sistema</b>"; print sprintf("• ACPI (zona): <b>%s°C</b> <i>(%s)</i>", t, chip); print "  - Nota: ACPI suele NO representar temperatura de CPU."; exit}
  '
}

tg3_section_html() {
  command -v sensors >/dev/null 2>&1 || return 0

  local lines max=0 n=0
  # extraer (chip temp)
  lines="$(sensors 2>/dev/null | awk '
    function clean(x){gsub(/[+°C]/,"",x); return x+0}
    /^[[:alnum:]][[:alnum:]_.:+-]*$/ {chip=$0; next}
    chip ~ /^tg3-pci-/ && /^temp1:/ {print chip, clean($2)}
  ')" || true

  [[ -z "$lines" ]] && return 0

  # calcular max y count
  while read -r chip t; do
    [[ -z "$chip" ]] && continue
    n=$((n+1))
    (( t > max )) && max="$t"
  done <<<"$lines"

  echo "<b>Red (NIC)</b>"
  echo "• Broadcom tg3 (sensores ${n}) máx: <b>${max}°C</b>"

  # lista por sensor con nombre "lindo" (si puede mapear a interfaz)
  while read -r chip t; do
    [[ -z "$chip" ]] && continue
    local short iface slot cand label
    short="${chip#tg3-pci-}"
    iface=""
    slot=""
    while read -r cand; do
      [[ -z "$cand" ]] && continue
      if iface="$(pci_ifname_by_slot "$cand" 2>/dev/null)"; then
        slot="$cand"
        break
      fi
    done < <(tg3_chip_to_slots "$chip" || true)

    if [[ -n "$iface" ]]; then
      label="  - ${iface} (PCI ${slot}): <b>${t}°C</b>"
    else
      label="  - tg3 ${short}: <b>${t}°C</b>"
    fi
    echo "$label"
  done <<<"$lines"
}

temp_groups_html() {
  local out="" part

  part="$(cpu_section_html || true)"
  if [[ -n "$part" ]]; then out+="$part"; fi

  part="$(tg3_section_html || true)"
  if [[ -n "$part" ]]; then
    [[ -n "$out" ]] && out+=$'\n\n'
    out+="$part"
  fi

  part="$(acpi_section_html || true)"
  if [[ -n "$part" ]]; then
    [[ -n "$out" ]] && out+=$'\n\n'
    out+="$part"
  fi

  # fallback a thermal zones si no hubo nada
  if [[ -z "$out" ]] && ls /sys/class/thermal/thermal_zone*/type >/dev/null 2>&1; then
    out="<b>Thermal zones</b>"
    for z in /sys/class/thermal/thermal_zone*; do
      local ty v
      ty="$(cat "$z/type" 2>/dev/null || true)"
      v="$(cat "$z/temp" 2>/dev/null || true)"
      [[ -n "$v" ]] && out+=$'\n'"• $(basename "$z") (${ty}): <b>$((v/1000))°C</b>"
    done
  fi

  echo "$out"
}

IP_LAN="$(hostname -I 2>/dev/null | awk '{print $1}')"
IP_PUBLIC="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"
[[ -z "$IP_PUBLIC" ]] && IP_PUBLIC="$(curl -fsS --max-time 3 https://ifconfig.me/ip 2>/dev/null || true)"

LOAD_PCT="$(load_pct)"
RAM_PCT="$(pct_used_mem)"
DISK_PCT="$(root_disk_pct)"

TEMP_CPU_MAX_C="$(cpu_pkg_max_c || true)"
TEMP_GROUPS="$(temp_groups_html || true)"

LOAD_SEV="$(sev "$LOAD_PCT" "$WARN_LOAD_PCT" "$CRIT_LOAD_PCT")"
RAM_SEV="$(sev "$RAM_PCT" "$WARN_RAM_PCT" "$CRIT_RAM_PCT")"
DISK_SEV="$(sev "$DISK_PCT" "$WARN_DISK_PCT" "$CRIT_DISK_PCT")"

TEMP_SEV="NA"
if [[ -n "${TEMP_CPU_MAX_C}" ]]; then
  TEMP_SEV="$(sev "$TEMP_CPU_MAX_C" "$WARN_TEMP_C" "$CRIT_TEMP_C")"
fi

FAILED_UNITS_RAW="$(systemctl --failed --no-legend 2>/dev/null | awk '{print $1}' | paste -sd, - || true)"
if [[ -n "$FAILED_UNITS_RAW" ]]; then
  FAILED_UNITS_LINE="🧩 Failed units: <code>${FAILED_UNITS_RAW}</code>"
else
  FAILED_UNITS_LINE="🧩 Failed units: <code>(none)</code>"
fi

UPGR="$(apt-get -s upgrade 2>/dev/null | awk '/^Inst /{c++} END{print c+0}' || echo 0)"

# alerts-only: también contempla failed units
if [[ "$BOOT_ALERTS_ONLY" == "true" ]]; then
  if [[ "$LOAD_SEV" == "OK" && "$RAM_SEV" == "OK" && "$DISK_SEV" == "OK" && ( "$TEMP_SEV" == "OK" || "$TEMP_SEV" == "NA" ) && -z "$FAILED_UNITS_RAW" ]]; then
    logger -t boot-report "SKIP: alerts-only, todo OK ($RUN_DATE)"
    echo "$RUN_DATE" > "$STAMP" 2>/dev/null || true
    exit 0
  fi
fi

TEMP_SECTION=""
if [[ -n "$TEMP_GROUPS" ]]; then
  TEMP_SECTION=$'\n\n'"<b>Temperaturas</b>"$'\n'"$TEMP_GROUPS"
fi

SLABEL="$(html_escape "$SERVER_LABEL")"
HOST_ESC="$(html_escape "$HOST")"

MSG="<b>DAILY REPORT</b>
🏷️ <b>${SLABEL}</b>
🖥️ ${HOST_ESC}
🌐 LAN: <code>${IP_LAN:-?}</code>
🌍 WAN: <code>${IP_PUBLIC:-?}</code>
🧠 Kernel: <code>${KERNEL}</code>
⏱️ Uptime: ${UPTIME}
🕒 ${DATE}

<b>Métricas</b>
$(icon "$LOAD_SEV") Load: <b>${LOAD_PCT}%</b>
$(icon "$RAM_SEV") RAM : <b>${RAM_PCT}%</b>
$(icon "$DISK_SEV") Disk: <b>${DISK_PCT}%</b>
$(icon "$TEMP_SEV") Temp CPU (máx package): <b>${TEMP_CPU_MAX_C:-n/a}°C</b>${TEMP_SECTION}

<b>Salud</b>
${FAILED_UNITS_LINE}
📦 Updates pending: <b>${UPGR}</b>
"

tg_send "$MSG"
echo "$RUN_DATE" > "$STAMP" 2>/dev/null || true
