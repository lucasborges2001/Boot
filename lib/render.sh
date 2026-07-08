#!/usr/bin/env bash
set -euo pipefail

# lib/render.sh
# Compatibilidad legacy: expone las mismas funciones públicas, divididas en módulos chicos.

if [[ -n "${BOOT_LEGACY_RENDER_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_LEGACY_RENDER_SH_INCLUDED=1

BOOT_LEGACY_RENDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/render" && pwd)"

source "$BOOT_LEGACY_RENDER_DIR/icons.sh"
source "$BOOT_LEGACY_RENDER_DIR/lists.sh"
source "$BOOT_LEGACY_RENDER_DIR/details.sh"
source "$BOOT_LEGACY_RENDER_DIR/buttons.sh"
source "$BOOT_LEGACY_RENDER_DIR/summary.sh"
source "$BOOT_LEGACY_RENDER_DIR/recommendations.sh"
source "$BOOT_LEGACY_RENDER_DIR/diagnostics.sh"
