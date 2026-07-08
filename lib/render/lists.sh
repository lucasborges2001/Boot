#!/usr/bin/env bash
# Helpers de listas para render legacy de Boot.

_render_trim_lines() {
  local max_lines="$1"
  awk -v n="$max_lines" 'NR<=n{print}'
}

_render_bullets() {
  local text="${1:-}" max_lines="${2:-30}"
  [[ -z "$text" ]] && return 0
  printf '%s\n' "$text" | _render_trim_lines "$max_lines" | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    echo "• $(tg_escape_html "$line")"
  done
}
