#!/usr/bin/env python3
"""Build the additive Boot telemetry schema v2 from collector environment values."""

import json
import os


def number(name: str, default: float = 0.0) -> float:
    try:
        return float(os.environ.get(name, default))
    except (TypeError, ValueError):
        return float(default)


def integer(name: str, default: int = 0) -> int:
    try:
        return int(float(os.environ.get(name, default)))
    except (TypeError, ValueError):
        return int(default)


def boolean_value(value: object, default: bool = False) -> bool:
    normalized = str(value if value is not None else default).strip().lower()
    return normalized in ("1", "true", "yes", "y", "on", "enabled")


def decode(name: str, default: object) -> object:
    try:
        value = json.loads(os.environ.get(name, ""))
        return value if isinstance(value, type(default)) else default
    except (TypeError, ValueError, json.JSONDecodeError):
        return default


def main() -> None:
    cpu = decode("BOOT_CPU_JSON", {})
    memory = decode("BOOT_MEMORY_JSON", {})
    filesystems = decode("BOOT_FILESYSTEMS_JSON", [])
    disk_io = decode("BOOT_DISK_IO_JSON", {})
    network_interfaces = decode("BOOT_NETWORK_JSON", [])
    failed = decode("BOOT_FAILED_SERVICES_VALUE", [])

    root_filesystem = next(
        (item for item in filesystems if item.get("mount") == "/" and item.get("available")),
        {},
    )
    ram_percent = memory.get("used_percent")
    swap_percent = memory.get("swap_used_percent")
    disk_percent = root_filesystem.get("used_percent")
    cpu_percent = cpu.get("used_percent")
    try:
        temperature = round(float(os.environ.get("BOOT_TEMPERATURE_VALUE", "null")), 1)
    except (TypeError, ValueError):
        temperature = None

    updates_total = integer("BOOT_UPDATES_TOTAL_VALUE")
    updates_security = integer("BOOT_UPDATES_SECURITY_VALUE")
    reboot_required = boolean_value(os.environ.get("BOOT_REBOOT_REQUIRED_VALUE"))
    failed_count = len(failed)

    warnings = []
    if cpu.get("available") is not True:
        warnings.append("cpu_unavailable")
    if memory.get("available") is not True:
        warnings.append("memory_unavailable")
    if not root_filesystem:
        warnings.append("root_filesystem_unavailable")
    for interface in network_interfaces:
        if interface.get("available") is not True:
            warnings.append("network_interface_unavailable:" + str(interface.get("name", "unknown")))

    severity, overall, summary = "ok", "ok", "Servidor estable"
    filesystem_critical = any(
        (item.get("used_percent") or 0) >= 95 for item in filesystems if item.get("available")
    )
    filesystem_warning = any(
        (item.get("used_percent") or 0) >= 85 for item in filesystems if item.get("available")
    )
    if filesystem_critical or (ram_percent or 0) >= 95 or (cpu_percent or 0) >= 98 or failed_count > 0:
        severity, overall, summary = "critical", "critical", "Servidor requiere intervención inmediata"
    elif filesystem_warning or (ram_percent or 0) >= 85 or (cpu_percent or 0) >= 90 or updates_security > 0 or reboot_required:
        severity, overall, summary = "warning", "warning", "Servidor estable con advertencias operativas"
    elif updates_total > 0 or warnings:
        severity, overall, summary = "info", "ok", "Servidor estable con información operativa pendiente"

    reports_dir = os.environ.get("BOOT_REPORTS_DIR_VALUE", "/var/lib/boot-report/reports").rstrip("/")
    report = {
        "module": "boot",
        "schema_version": 2,
        "generated_at": os.environ.get("BOOT_GENERATED_AT_VALUE", ""),
        "server": {
            "hostname": os.environ.get("BOOT_HOSTNAME_VALUE", "unknown"),
            "kernel": os.environ.get("BOOT_KERNEL_VALUE", "unknown"),
            "uptime_seconds": integer("BOOT_UPTIME_VALUE"),
            "cpu_logical": cpu.get("logical"),
            "ip_lan": os.environ.get("BOOT_IP_LAN_VALUE") or None,
            "ip_wan": None,
        },
        "status": {"overall": overall, "severity": severity, "summary": summary},
        "metrics": {
            "cpu_used_percent": cpu_percent,
            "cpu_load_1m": round(number("BOOT_LOAD_1_VALUE"), 2),
            "cpu_load_5m": round(number("BOOT_LOAD_5_VALUE"), 2),
            "cpu_load_15m": round(number("BOOT_LOAD_15_VALUE"), 2),
            "ram_used_percent": ram_percent,
            "swap_used_percent": swap_percent,
            "disk_root_used_percent": disk_percent,
            "temperature_c": temperature,
        },
        "cpu": cpu,
        "memory": memory,
        "filesystems": filesystems,
        "disk_io": disk_io,
        "network_interfaces": network_interfaces,
        "updates": {
            "total": updates_total,
            "security": updates_security,
            "reboot_required": reboot_required,
        },
        "services": {"failed_count": failed_count, "failed": failed},
        "collection": {
            "warnings": warnings,
            "network_rates_require_previous_snapshot": True,
        },
        "units": {
            "percent": "0..100",
            "bytes": "bytes",
            "rates": "per_second",
            "load_average": "runnable_tasks_average",
            "temperature": "celsius",
            "cpu_counters": "jiffies",
        },
        "telegram": {
            "enabled": boolean_value(os.environ.get("BOOT_TELEGRAM_ENABLED_VALUE"), True),
            "last_send_ok": None,
            "message_id": None,
            "description": None,
        },
        "artifacts": {
            "report_json": reports_dir + "/latest/report.json",
            "summary_txt": reports_dir + "/latest/summary.txt",
        },
    }
    print(json.dumps(report, ensure_ascii=False, separators=(",", ":")))


if __name__ == "__main__":
    main()
