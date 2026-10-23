#!/usr/bin/env python3
"""Render Boot systemd units for an isolated ~/servidor/ layout.

Pure renderer: it never installs units, changes permissions, or runs systemctl.
The legacy /opt installer remains unchanged.
"""
import argparse
from pathlib import Path
import re
import sys


UNITS = ("boot-report.service", "boot-report.timer")


def validate_root(value: str) -> Path:
    # Fixed layout intentionally excludes system roots, whitespace and directives.
    if not re.fullmatch(r"/home/[a-z_][a-z0-9_-]*/servidor", value):
        raise ValueError("root must be /home/<account>/servidor")
    root = Path(value)
    if any(part.is_symlink() for part in (root.parent.parent, root.parent, root)):
        raise ValueError("root or ancestor is a symlink")
    return root


def render(root: Path, unit: str) -> str:
    if unit == "boot-report.service":
        return f"""[Unit]
Description=Boot server observability (servidor layout)
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=bootreport
Group=bootreport
Environment=BASE_DIR={root}/current/base
Environment=BOOT_REPORTS_DIR={root}/state/boot/reports
EnvironmentFile={root}/config/boot/server.env
ExecStart={root}/current/boot/bin/boot-report
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths={root}/state/boot
LockPersonality=true
MemoryDenyWriteExecute=true
UMask=0027
"""
    if unit == "boot-report.timer":
        return """[Unit]
Description=Run Boot observability every 15 minutes (servidor layout)

[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
AccuracySec=30s
Persistent=true
Unit=boot-report.service

[Install]
WantedBy=timers.target
"""
    raise ValueError("unknown unit")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, help="absolute /home/<account>/servidor")
    parser.add_argument("--unit", choices=UNITS, required=True)
    args = parser.parse_args()
    try:
        root = validate_root(args.root)
        sys.stdout.write(render(root, args.unit))
    except ValueError as error:
        parser.error(str(error))
    return 0


if __name__ == "__main__":
    sys.exit(main())
