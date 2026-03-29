#!/usr/bin/env bash
set -euo pipefail

BOOT_STATE_DIR="${BOOT_STATE_DIR:-/var/lib/boot-report}"
BOOT_REPORTS_DIR="${BOOT_REPORTS_DIR:-${BOOT_STATE_DIR}/reports}"
BOOT_REPORT_RETENTION_DAYS="${BOOT_REPORT_RETENTION_DAYS:-30}"
BOOT_REPORT_RETENTION_COUNT="${BOOT_REPORT_RETENTION_COUNT:-60}"

BOOT_RUN_ID=""
BOOT_RUN_DIR=""
BOOT_REPORT_JSON=""
BOOT_REPORT_TXT=""
BOOT_OVERALL_SEV="OK"
BOOT_PHASES=""
BOOT_PHASE_CURRENT=""
BOOT_PHASE_CURRENT_START=""
BOOT_NOTIFY_STATUS="not_run"

runtime_init() {
  mkdir -p "$BOOT_STATE_DIR" "$BOOT_REPORTS_DIR"
  BOOT_RUN_ID="$(date -u '+%Y%m%dT%H%M%SZ')"
  BOOT_RUN_DIR="${BOOT_REPORTS_DIR}/${BOOT_RUN_ID}"
  BOOT_REPORT_JSON="${BOOT_RUN_DIR}/report.json"
  BOOT_REPORT_TXT="${BOOT_RUN_DIR}/summary.txt"
  mkdir -p "$BOOT_RUN_DIR"
}

runtime_now_epoch() {
  date +%s
}

runtime_max_sev() {
  local a="${1:-OK}" b="${2:-OK}"
  local rank_a rank_b
  case "$a" in
    ERROR|CRIT) rank_a=3 ;;
    WARN) rank_a=2 ;;
    SKIP) rank_a=1 ;;
    *) rank_a=0 ;;
  esac
  case "$b" in
    ERROR|CRIT) rank_b=3 ;;
    WARN) rank_b=2 ;;
    SKIP) rank_b=1 ;;
    *) rank_b=0 ;;
  esac
  if (( rank_a >= rank_b )); then
    echo "$a"
  else
    echo "$b"
  fi
}

runtime_phase_begin() {
  BOOT_PHASE_CURRENT="$1"
  BOOT_PHASE_CURRENT_START="$(runtime_now_epoch)"
}

runtime_phase_end() {
  local status="$1" summary="$2"
  local end_ts duration
  end_ts="$(runtime_now_epoch)"
  duration=$((end_ts - BOOT_PHASE_CURRENT_START))
  BOOT_PHASES+="${BOOT_PHASE_CURRENT}|${status}|${duration}|${summary}"$'\n'
  BOOT_OVERALL_SEV="$(runtime_max_sev "$BOOT_OVERALL_SEV" "$status")"
  BOOT_PHASE_CURRENT=""
  BOOT_PHASE_CURRENT_START=""
}

runtime_latest_link() {
  ln -sfn "$BOOT_RUN_DIR" "${BOOT_REPORTS_DIR}/latest"
}

runtime_cleanup_reports() {
  local base="$BOOT_REPORTS_DIR"
  find "$base" -mindepth 1 -maxdepth 1 -type d -name '20*Z' -mtime "+${BOOT_REPORT_RETENTION_DAYS}" -exec rm -rf {} + 2>/dev/null || true
  local dirs
  mapfile -t dirs < <(find "$base" -mindepth 1 -maxdepth 1 -type d -name '20*Z' | sort)
  local count="${#dirs[@]}"
  if (( count > BOOT_REPORT_RETENTION_COUNT )); then
    local remove_count=$((count - BOOT_REPORT_RETENTION_COUNT))
    local i
    for ((i=0; i<remove_count; i++)); do
      rm -rf "${dirs[$i]}" 2>/dev/null || true
    done
  fi
}

runtime_write_summary() {
  local content="$1"
  printf '%s\n' "$content" > "$BOOT_REPORT_TXT"
}

runtime_write_json() {
  local notify_sent="$1" message_ids="$2"
  python3 - "$BOOT_REPORT_JSON" "$BOOT_RUN_ID" "$BOOT_OVERALL_SEV" "$notify_sent" "$message_ids" <<'PY'
import json, os, sys
from pathlib import Path

out_path, run_id, overall, notify_sent, message_ids_raw = sys.argv[1:6]

def env(name, default=""):
    return os.environ.get(name, default)

def int_env(name, default=0):
    try:
        return int(os.environ.get(name, default))
    except Exception:
        return default

phases=[]
for line in env("BOOT_PHASES").splitlines():
    if not line.strip():
        continue
    name, status, duration, summary = line.split("|", 3)
    phases.append({
        "name": name,
        "status": status.lower(),
        "duration_sec": int(duration),
        "summary": summary,
    })

message_ids={}
for line in message_ids_raw.splitlines():
    if not line.strip() or "=" not in line:
        continue
    k,v = line.split("=",1)
    message_ids[k]=v

report = {
    "run_id": run_id,
    "server": {
        "label": env("SERVER_LABEL", env("HOST", "")),
        "host": env("HOST", ""),
        "date": env("DATE", ""),
        "kernel": env("KERNEL", ""),
        "uptime": env("UPTIME", ""),
        "ip_lan": env("IP_LAN", ""),
        "ip_wan": env("IP_WAN", ""),
    },
    "overall_status": overall.lower(),
    "notify": {
        "status": notify_sent,
        "channel": "telegram",
        "message_ids": message_ids,
    },
    "signals": {
        "load": {"value_pct": int_env("LOAD_PCT"), "severity": env("LOAD_SEV", "").lower(), "trend": env("LOAD_TREND", "")},
        "ram": {"value_pct": int_env("RAM_PCT"), "severity": env("RAM_SEV", "").lower(), "trend": env("RAM_TREND", "")},
        "disk": {"value_pct": int_env("DISK_PCT"), "severity": env("DISK_SEV", "").lower(), "trend": env("DISK_TREND", "")},
        "temp": {"value_c": env("TEMP_CPU_MAX_C", ""), "severity": env("TEMP_SEV", "").lower()},
        "updates": {"total": int_env("UPDATES_COUNT"), "security": int_env("UPD_SEC_N")},
        "services": {"failed": int_env("FAILED_COUNT")},
        "smart": {"status": env("SMART_STATUS", "").lower()},
    },
    "phases": phases,
    "artifacts": {
        "summary_txt": str(Path(out_path).with_name("summary.txt")),
    },
}

Path(out_path).write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}
