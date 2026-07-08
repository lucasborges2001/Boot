#!/usr/bin/env bash
set -euo pipefail

# lib/system.sh
# Compatibilidad legacy: expone las mismas funciones públicas, divididas por dominio.

if [[ -n "${BOOT_LEGACY_SYSTEM_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_LEGACY_SYSTEM_SH_INCLUDED=1

BOOT_LEGACY_SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/system" && pwd)"

source "$BOOT_LEGACY_SYSTEM_DIR/basic.sh"
source "$BOOT_LEGACY_SYSTEM_DIR/network.sh"
source "$BOOT_LEGACY_SYSTEM_DIR/temperature.sh"
source "$BOOT_LEGACY_SYSTEM_DIR/updates.sh"
source "$BOOT_LEGACY_SYSTEM_DIR/services.sh"
source "$BOOT_LEGACY_SYSTEM_DIR/processes.sh"
source "$BOOT_LEGACY_SYSTEM_DIR/disk.sh"
source "$BOOT_LEGACY_SYSTEM_DIR/trends.sh"
