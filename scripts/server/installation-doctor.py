#!/usr/bin/env python3
"""Read-only on-disk diagnosis of Boot v2 vs pre-v2 installations."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import sys

SERVICE = "etc/systemd/system/boot-report.service"
TIMER = "etc/systemd/system/boot-report.timer"
BINARY = "opt/boot-report/bin/boot-report"
REPORT = "var/lib/boot-report/reports/latest/report.json"
EXEC = "ExecStart=/opt/boot-report/bin/boot-report"
MAX_SIZE = 2097152


def state(root: Path, ttl: int, now: datetime) -> dict:
    checks = {}
    for name, rel, marker in [
        ("service", SERVICE, EXEC),
        ("timer", TIMER, "OnUnitActiveSec=15min"),
    ]:
        path = root / rel
        try:
            if not path.is_file():
                checks[name] = "MISSING"
            else:
                contents = path.read_text(encoding="utf-8")
                checks[name] = "MATCH" if marker in contents.splitlines() else "LEGACY_OR_DRIFT"
        except (OSError, UnicodeError):
            checks[name] = "UNREADABLE"
    try:
        checks["binary"] = "PRESENT" if (root / BINARY).is_file() else "MISSING"
    except OSError:
        checks["binary"] = "UNREADABLE"
    path = root / REPORT
    checks["snapshot"] = "MISSING"
    try:
        if path.is_file():
            if path.stat().st_size > MAX_SIZE:
                checks["snapshot"] = "TOO_LARGE"
            else:
                obj = json.loads(path.read_text(encoding="utf-8"))
                if not isinstance(obj, dict) or obj.get("module") != "boot" or obj.get("schema_version") not in (1, 2):
                    checks["snapshot"] = "INVALID_CONTRACT"
                else:
                    ts = datetime.fromisoformat(str(obj.get("generated_at", "")).replace("Z", "+00:00"))
                    age = (now - ts).total_seconds()
                    checks["snapshot"] = "FRESH" if -60 <= age <= ttl else "STALE_OR_CLOCK_SKEW"
    except (ValueError, UnicodeError, TypeError):
        checks["snapshot"] = "INVALID_REPORT"
    except PermissionError:
        checks["snapshot"] = "UNREADABLE"
    except OSError:
        checks["snapshot"] = "UNAVAILABLE"
    legacy = "LEGACY_OR_DRIFT" in checks.values()
    complete = (checks["service"] == "MATCH" and checks["timer"] == "MATCH"
                and checks["binary"] == "PRESENT" and checks["snapshot"] == "FRESH")
    classification = "LEGACY_OR_DRIFT" if legacy else "CONTRACT_OK_DISK" if complete else "INCOMPLETE"
    return {"module": "boot", "classification": classification, "checks": checks,
            "runtime_verified": False, "writes": False}


def main() -> int:
    cli = argparse.ArgumentParser(description="Boot installation doctor, read-only")
    cli.add_argument("--root", type=Path, default=Path("/"), help="filesystem root; for fixtures only")
    cli.add_argument("--ttl", type=int, default=1200)
    args = cli.parse_args()
    if not args.root.is_absolute() or not args.root.is_dir() or not 30 <= args.ttl <= 86400:
        cli.error("invalid root or TTL")
    report = state(args.root, args.ttl, datetime.now(timezone.utc))
    print(json.dumps(report, sort_keys=True))
    return 0 if report["classification"] == "CONTRACT_OK_DISK" else 1


if __name__ == "__main__":
    sys.exit(main())
