#!/usr/bin/env bash
# Temperatura y sensores legacy para Boot.

sys_cpu_pkg_max_c() {
  if command -v sensors >/dev/null 2>&1; then
    sensors 2>/dev/null | awk '
      function clean(x){gsub(/[+°C]/,"",x); return x+0}
      /Package id [0-9]+:/ {t=clean($4); if(t>max) max=t}
      END{ if(max>0) print int(max) }
    '
    return 0
  fi

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
