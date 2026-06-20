#!/usr/bin/env bash
# Boot-specific persistence for report.json and summary.txt.

if [[ -n "${BOOT_PERSIST_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_PERSIST_SH_INCLUDED=1

boot_persist_report() {
  local json="${1:?report json is required}"
  local summary="${2:?summary text is required}"
  local reports_dir="${3:-${BOOT_REPORTS_DIR:-/var/lib/boot-report/reports}}"
  mkdir -p "$reports_dir/latest"
  local stamp
  stamp="$(printf '%s' "$json" | python3 -c 'import json,sys,re; d=json.load(sys.stdin); s=d.get("generated_at") or "unknown"; print(re.sub(r"[^0-9A-Za-z_.-]", "-", s))')"
  [[ -n "$stamp" ]] || stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
  local snapshot_dir="$reports_dir/$stamp"
  mkdir -p "$snapshot_dir"
  printf '%s\n' "$json" > "$reports_dir/latest/report.json.tmp"
  printf '%s\n' "$summary" > "$reports_dir/latest/summary.txt.tmp"
  base_json_file_is_valid "$reports_dir/latest/report.json.tmp"
  mv "$reports_dir/latest/report.json.tmp" "$reports_dir/latest/report.json"
  mv "$reports_dir/latest/summary.txt.tmp" "$reports_dir/latest/summary.txt"
  cp "$reports_dir/latest/report.json" "$snapshot_dir/report.json"
  cp "$reports_dir/latest/summary.txt" "$snapshot_dir/summary.txt"
}

boot_update_latest_symlink() {
  local reports_dir="${1:?reports dir is required}" snapshot_dir="${2:?snapshot dir is required}"
  ln -sfn "$snapshot_dir" "$reports_dir/latest"
}

boot_prune_old_reports() {
  local reports_dir="${1:-${BOOT_REPORTS_DIR:-/var/lib/boot-report/reports}}" days="${2:-${BOOT_RETENTION_DAYS:-14}}"
  [[ -d "$reports_dir" ]] || return 0
  [[ "$days" =~ ^[0-9]+$ ]] || days=14
  find "$reports_dir" -mindepth 1 -maxdepth 1 -type d ! -name latest -mtime "+$days" -exec rm -rf {} + 2>/dev/null || true
}
