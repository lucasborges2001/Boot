#!/usr/bin/env bash
set -euo pipefail

# lib/system.sh
# Responsabilidad única: recolectar datos del sistema (sin formatear mensajes).

sys_hostname() {
  hostname -f 2>/dev/null || hostname
}

sys_now() {
  date '+%Y-%m-%d %H:%M:%S %Z'
}

sys_kernel() {
  uname -r
}

sys_uptime_pretty() {
  uptime -p 2>/dev/null || true
}

sys_ip_lan() {
  hostname -I 2>/dev/null | awk '{print $1}'
}

sys_ip_wan() {
  local ip
  ip="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"
  [[ -z "$ip" ]] && ip="$(curl -fsS --max-time 3 https://ifconfig.me/ip 2>/dev/null || true)"
  echo "$ip"
}

sys_pct_used_mem() {
  local total avail used
  total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
  avail=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
  used=$((total - avail))
  echo $(( used * 100 / total ))
}

sys_root_disk_pct() {
  df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
}

sys_load_pct() {
  local load cpu
  load=$(awk '{print $1}' /proc/loadavg)
  cpu=$(nproc)
  awk -v l="$load" -v c="$cpu" 'BEGIN{printf "%d", (l/c)*100}'
}

sys_cpu_pkg_max_c() {
  # Temperatura máxima de CPU Package
  if command -v sensors >/dev/null 2>&1; then
    sensors 2>/dev/null | awk '
      function clean(x){gsub(/[+°C]/,"",x); return x+0}
      /Package id [0-9]+:/ {t=clean($4); if(t>max) max=t}
      END{ if(max>0) print int(max) }
    '
    return 0
  fi

  # Fallback: thermal zones tipo x86_pkg_temp
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

# --- Sensores detallados ---

_pci_ifname_by_slot() {
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

_tg3_chip_to_slots() {
  local chip="$1" short bus
  short="${chip#tg3-pci-}"
  bus="${short:0:2}"
  if [[ "$short" =~ ^[0-9]{4}$ ]]; then
    echo "0000:${bus}:00.${short:3:1}"
    echo "0000:${bus}:${short:2:2}.0"
  fi
}

_cpu_section_html() {
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
      print sprintf("• CPU (máx): <b>%d°C</b>", int(cpu_max+0.5))
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

_acpi_section_html() {
  command -v sensors >/dev/null 2>&1 || return 0
  sensors 2>/dev/null | awk '
    function clean(x){gsub(/[+°C]/,"",x); return x}
    /^[[:alnum:]][[:alnum:]_.:+-]*$/ {chip=$0; next}
    chip ~ /^acpitz-acpi-/ && /^temp1:/ {
      t=clean($2)
      print "<b>Sistema</b>"
      print sprintf("• ACPI (zona): <b>%s°C</b> <i>(%s)</i>", t, chip)
      exit
    }
  '
}

_tg3_section_html() {
  command -v sensors >/dev/null 2>&1 || return 0

  local lines max=0 n=0
  lines="$(sensors 2>/dev/null | awk '
    function clean(x){gsub(/[+°C]/,"",x); return x+0}
    /^[[:alnum:]][[:alnum:]_.:+-]*$/ {chip=$0; next}
    chip ~ /^tg3-pci-/ && /^temp1:/ {print chip, clean($2)}
  ' || true)"

  [[ -z "$lines" ]] && return 0

  while read -r chip t; do
    [[ -z "$chip" ]] && continue
    n=$((n+1))
    (( t > max )) && max="$t"
  done <<<"$lines"

  echo "<b>Red (NIC)</b>"
  echo "• Broadcom tg3 (sensores ${n}) máx: <b>${max}°C</b>"

  while read -r chip t; do
    [[ -z "$chip" ]] && continue
    local short iface slot cand label
    short="${chip#tg3-pci-}"
    iface=""
    slot=""
    while read -r cand; do
      [[ -z "$cand" ]] && continue
      if iface="$(_pci_ifname_by_slot "$cand" 2>/dev/null)"; then
        slot="$cand"
        break
      fi
    done < <(_tg3_chip_to_slots "$chip" || true)

    if [[ -n "$iface" ]]; then
      label="  - ${iface} (PCI ${slot}): <b>${t}°C</b>"
    else
      label="  - tg3 ${short}: <b>${t}°C</b>"
    fi
    echo "$label"
  done <<<"$lines"
}

sys_temp_groups_html() {
  local out="" part

  part="$(_cpu_section_html || true)"
  if [[ -n "$part" ]]; then out+="$part"; fi

  part="$(_tg3_section_html || true)"
  if [[ -n "$part" ]]; then
    [[ -n "$out" ]] && out+=$'\n\n'
    out+="$part"
  fi

  part="$(_acpi_section_html || true)"
  if [[ -n "$part" ]]; then
    [[ -n "$out" ]] && out+=$'\n\n'
    out+="$part"
  fi

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

sys_failed_units_list() {
  systemctl --failed --no-legend 2>/dev/null | awk '{print $1}'
}

sys_updates_snapshot() {
  # Salida en 3 bloques, para parsear sin jq:
  # --SECURITY--\n<pkgs>\n--REGULAR--\n<pkgs>\n--HELD--\n<pkgs>

  local sim holds
  sim="$(apt-get -s upgrade 2>/dev/null || true)"
  holds="$(apt-mark showhold 2>/dev/null || true)"

  python3 -c 'import re,sys
holds=set([x.strip() for x in sys.argv[1].splitlines() if x.strip()])
sec=[]; reg=[]
for line in sys.stdin.read().splitlines():
    if not line.startswith("Inst "):
        continue
    m=re.match(r"^Inst\s+(\S+)(?:\s+\[[^\]]+\])?\s+\(([^ \s]+)\s+([^)]*)\)$", line)
    if not m:
        m=re.match(r"^Inst\s+(\S+)\s+\(([^)]*)\)$", line)
        if not m:
            continue
        pkg=m.group(1); origin=m.group(2)
    else:
        pkg=m.group(1); origin=m.group(3)
    o=origin.lower()
    is_sec=("security" in o) or ("-security" in o)
    (sec if is_sec else reg).append(pkg)

def uniq(xs):
    seen=set(); out=[]
    for x in xs:
        if x not in seen:
            out.append(x); seen.add(x)
    return out

sec=uniq(sec); reg=uniq(reg)
print("--SECURITY--")
print("\n".join(sec))
print("--REGULAR--")
print("\n".join(reg))
print("--HELD--")
print("\n".join(sorted(holds)))' "$holds" <<<"$sim"
}


# --- Mejoras: Indicadores, proximidad, recomendaciones ---

sys_pct_proximity_to_limit() {
  # args: current_pct limit_pct
  # Retorna: % de proximidad al límite (ej: 80% de 85% = 94% proximidad)
  local current="$1" limit="$2"
  if [[ "$current" -ge "$limit" ]]; then
    echo "100"
  else
    awk -v c="$current" -v l="$limit" 'BEGIN{printf "%d", (c/l)*100}'
  fi
}

sys_top_processes() {
  # args: metric (cpu|mem) count
  # Retorna: "name pid%%\nname pid%%\n..."
  local metric="$1" count="${2:-5}"
  if [[ "$metric" == "cpu" ]]; then
    ps aux --sort=-%cpu | awk -v n="$count" 'NR>1 && NR<=n+1 {cmd=$11; sub(".*/","",cmd); printf "%s %s %.1f\n", cmd, $2, $3}'
  elif [[ "$metric" == "mem" ]]; then
    ps aux --sort=-%mem | awk -v n="$count" 'NR>1 && NR<=n+1 {cmd=$11; sub(".*/","",cmd); printf "%s %s %.1f\n", cmd, $2, $4}'
  fi
}

sys_smartctl_status() {
  # Retorna: estado del disco (PASS|FAIL|UNKNOWN)
  local status="UNKNOWN"
  if command -v smartctl >/dev/null 2>&1; then
    # Intenta /dev/sda primero (disco raíz típico)
    local dev result
    for dev in /dev/sda /dev/nvme0n1 /dev/sdb; do
      if [[ ! -e "$dev" ]]; then continue; fi
      # Intenta sin sudo primero
      result="$(smartctl -H "$dev" 2>/dev/null || smartctl -H "$dev" -d auto 2>/dev/null || true)"
      if echo "$result" | grep -qi "overall.*health.*passed"; then
        status="PASS"
        break
      elif echo "$result" | grep -qi "overall.*health.*failed"; then
        status="FAIL"
        break
      fi
    done
  fi
  echo "$status"
}

sys_network_info() {
  # Retorna: ifaces activas, gateway, DNS (formato: line\nline\n...)
  local out=""
  
  # Interfaces activas
  out="Interfaces"$'\n'
  if command -v ip >/dev/null 2>&1; then
    ip -br addr show 2>/dev/null | awk '$2=="UP"||$2=="UP,LOOPBACK" {printf "• %s: %s\n", $1, $3}' | while read -r line; do
      out+="$line"$'\n'
    done || true
  fi
  
  # Gateway
  local gw
  if command -v ip >/dev/null 2>&1; then
    gw="$(ip route 2>/dev/null | awk '$1=="default" {print $3; exit}')" || true
    if [[ -n "$gw" ]]; then
      out+=$'\n'"Gateway"$'\n'"• ${gw}"$'\n'
    fi
  fi
  
  # DNS
  local dns_list
  dns_list="$(grep -h nameserver /etc/resolv.conf 2>/dev/null | awk '{print $2}' | head -2 | tr '\n' ' ')" || true
  if [[ -n "$dns_list" ]]; then
    out+=$'\n'"DNS"$'\n'"• ${dns_list}"
  fi
  
  echo -e "$out"
}

sys_service_changes() {
  # Retorna: cambios desde el último reporte (start|stop)
  # Guarda estado en /var/lib/boot-report/last_services
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
  
  # Detectar cambios simples comparando líneas
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

sys_critical_alerts() {
  # args: load_sev ram_sev disk_sev temp_sev failed_count upd_sec_n
  # Retorna: lista de alertas críticas (vacío si todo OK)
  local load_sev="$1" ram_sev="$2" disk_sev="$3" temp_sev="$4" failed_count="$5" upd_sec_n="$6"
  local alerts=""
  
  [[ "$load_sev" == "CRIT" ]] && alerts+="• Load crítica"$'\n'
  [[ "$ram_sev" == "CRIT" ]] && alerts+="• RAM crítica"$'\n'
  [[ "$disk_sev" == "CRIT" ]] && alerts+="• Disco crítico"$'\n'
  [[ "$temp_sev" == "CRIT" ]] && alerts+="• Temperatura crítica"$'\n'
  [[ "$failed_count" -gt 0 ]] && alerts+="• $failed_count servicios fallidos"$'\n'
  [[ "$upd_sec_n" -gt 0 ]] && alerts+="• $upd_sec_n actualizaciones de SEGURIDAD"$'\n'
  
  echo -e "$alerts"
}

sys_metric_trend() {
  # args: current_value metric_name (load|ram|disk)
  # Retorna: "direction percentage" (ej: "↗ +5" o "↘ -2" o "→ 0")
  local current="$1" metric="$2"
  local statefile="/var/lib/boot-report/last_${metric}"
  
  mkdir -p "$(dirname "$statefile")" 2>/dev/null || true
  
  if [[ ! -f "$statefile" ]]; then
    echo "$current" > "$statefile" 2>/dev/null || true
    echo "→ 0"
    return 0
  fi
  
  local prev
  prev="$(cat "$statefile" 2>/dev/null || echo "$current")"
  
  local diff
  diff=$((current - prev))
  
  local direction
  if [[ "$diff" -gt 0 ]]; then
    direction="↗"
  elif [[ "$diff" -lt 0 ]]; then
    direction="↘"
  else
    direction="→"
  fi
  
  echo "$current" > "$statefile" 2>/dev/null || true
  echo "$direction $(printf '%+d' "$diff")"
}