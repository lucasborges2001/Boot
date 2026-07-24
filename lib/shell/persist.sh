#!/usr/bin/env bash
# Boot-specific persistence for report.json and summary.txt.

if [[ -n "${BOOT_PERSIST_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_PERSIST_SH_INCLUDED=1

_boot_snapshot_stamp() {
  local json="${1:?report json is required}"
  printf '%s' "$json" | python3 -c '
import datetime as dt, json, sys
try:
    value = json.load(sys.stdin).get("generated_at")
    parsed = dt.datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    print(parsed.astimezone(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ"))
except Exception:
    print(dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ"))
'
}

boot_persist_report() {
  local json="${1:?report json is required}"
  local summary="${2:?summary text is required}"
  local reports_dir="${3:-${BOOT_REPORTS_DIR:-/var/lib/boot-report/reports}}"
  local latest_dir="$reports_dir/latest"
  local stamp snapshot_dir snapshot_tmp report_tmp summary_tmp

  mkdir -p "$latest_dir"
  stamp="$(_boot_snapshot_stamp "$json")"
  snapshot_dir="$reports_dir/$stamp"
  if [[ -e "$snapshot_dir" ]]; then
    snapshot_dir="$reports_dir/${stamp}-$(date -u '+%N')-$$"
  fi
  snapshot_tmp="$reports_dir/.snapshot-${stamp}-$$"
  report_tmp="$latest_dir/.report.json.$$.tmp"
  summary_tmp="$latest_dir/.summary.txt.$$.tmp"

  rm -rf "$snapshot_tmp"
  mkdir -p "$snapshot_tmp"
  printf '%s\n' "$json" > "$snapshot_tmp/report.json"
  printf '%s\n' "$summary" > "$snapshot_tmp/summary.txt"
  base_json_file_is_valid "$snapshot_tmp/report.json"

  printf '%s\n' "$json" > "$report_tmp"
  printf '%s\n' "$summary" > "$summary_tmp"
  base_json_file_is_valid "$report_tmp"

  mv "$snapshot_tmp" "$snapshot_dir"
  mv "$report_tmp" "$latest_dir/report.json"
  mv "$summary_tmp" "$latest_dir/summary.txt"
}

boot_update_latest_symlink() {
  local reports_dir="${1:?reports dir is required}"
  local snapshot_dir="${2:?snapshot dir is required}"
  [[ "$snapshot_dir" == "$reports_dir"/* ]] || return 2
  ln -sfn "$snapshot_dir" "$reports_dir/latest"
}

boot_prune_old_reports() {
  local reports_dir="${1:-${BOOT_REPORTS_DIR:-/var/lib/boot-report/reports}}"
  local days="${2:-${BOOT_HISTORY_RETENTION_DAYS:-${BOOT_RETENTION_DAYS:-30}}}"
  local max_files="${3:-${BOOT_HISTORY_MAX_FILES:-50000}}"
  [[ -d "$reports_dir" ]] || return 0
  [[ "$days" =~ ^[0-9]+$ ]] || days=30
  [[ "$max_files" =~ ^[0-9]+$ ]] || max_files=50000

  BOOT_PRUNE_ROOT="$reports_dir" BOOT_PRUNE_DAYS="$days" BOOT_PRUNE_MAX_FILES="$max_files" python3 - <<'PY'
import os
import re
import shutil
import time

root = os.path.realpath(os.environ['BOOT_PRUNE_ROOT'])
days = int(os.environ.get('BOOT_PRUNE_DAYS', '30'))
max_files = int(os.environ.get('BOOT_PRUNE_MAX_FILES', '50000'))
if not os.path.isdir(root) or root == os.path.sep:
    raise SystemExit(2)

name_pattern = re.compile(r'^(?:\d{8}T\d{6}Z(?:-[A-Za-z0-9.-]+)?|\d{4}-\d{2}-\d{2}T[A-Za-z0-9_.:+-]+)$')
candidates = []
for entry in os.scandir(root):
    if entry.name == 'latest' or entry.is_symlink() or not entry.is_dir(follow_symlinks=False):
        continue
    if not name_pattern.fullmatch(entry.name) or not os.path.isfile(os.path.join(entry.path, 'report.json')):
        continue
    candidates.append((entry.stat(follow_symlinks=False).st_mtime, entry.path))

candidates.sort(reverse=True)
now = time.time()
cutoff = now - days * 86400 if days > 0 else None
to_delete = set()
for index, (mtime, path) in enumerate(candidates):
    if cutoff is not None and mtime < cutoff:
        to_delete.add(path)
    if max_files > 0 and index >= max_files:
        to_delete.add(path)

for path in sorted(to_delete):
    resolved = os.path.realpath(path)
    if os.path.dirname(resolved) != root or not os.path.basename(resolved):
        continue
    shutil.rmtree(resolved)
PY
}
