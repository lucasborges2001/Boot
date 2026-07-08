#!/usr/bin/env bash
# Red legacy para Boot.

sys_ip_wan() {
  local ip
  ip="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"
  [[ -z "$ip" ]] && ip="$(curl -fsS --max-time 3 https://ifconfig.me/ip 2>/dev/null || true)"
  echo "$ip"
}

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

sys_network_info() {
  local out=""

  out="Interfaces"$'\n'
  if command -v ip >/dev/null 2>&1; then
    ip -br addr show 2>/dev/null | awk '$2=="UP"||$2=="UP,LOOPBACK" {printf "• %s: %s\n", $1, $3}' | while read -r line; do
      out+="$line"$'\n'
    done || true
  fi

  local gw
  if command -v ip >/dev/null 2>&1; then
    gw="$(ip route 2>/dev/null | awk '$1=="default" {print $3; exit}')" || true
    if [[ -n "$gw" ]]; then
      out+=$'\n'"Gateway"$'\n'"• ${gw}"$'\n'
    fi
  fi

  local dns_list
  dns_list="$(grep -h nameserver /etc/resolv.conf 2>/dev/null | awk '{print $2}' | head -2 | tr '\n' ' ')" || true
  if [[ -n "$dns_list" ]]; then
    out+=$'\n'"DNS"$'\n'"• ${dns_list}"
  fi

  echo -e "$out"
}
