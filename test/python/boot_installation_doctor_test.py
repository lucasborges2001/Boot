#!/usr/bin/env python3
"""Isolated read-only checks of installed Boot layouts."""
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

DOCTOR = Path(__file__).resolve().parents[2] / "scripts/server/installation-doctor.py"


class BootInstallDoctorTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="boot-doctor-")
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        for folder in ("etc/systemd/system", "opt/boot-report/bin", "var/lib/boot-report/reports/latest"):
            (self.root / folder).mkdir(parents=True)
        (self.root / "etc/systemd/system/boot-report.service").write_text("ExecStart=/opt/boot-report/bin/boot-report\n")
        (self.root / "etc/systemd/system/boot-report.timer").write_text("OnUnitActiveSec=15min\n")
        (self.root / "opt/boot-report/bin/boot-report").write_text("#!/bin/sh\n")
        self.report = self.root / "var/lib/boot-report/reports/latest/report.json"
        self.write_report()

    def write_report(self, delay=60):
        self.report.write_text(json.dumps({
            "module": "boot", "schema_version": 2,
            "generated_at": (datetime.now(timezone.utc) - timedelta(seconds=delay)).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }))

    def run_doctor(self):
        result = subprocess.run([sys.executable, str(DOCTOR), "--root", str(self.root)], capture_output=True, text=True)
        return result, json.loads(result.stdout)

    def test_valid_layout_is_disk_only(self):
        result, data = self.run_doctor()
        self.assertEqual(0, result.returncode)
        self.assertEqual("CONTRACT_OK_DISK", data["classification"])
        self.assertFalse(data["runtime_verified"])

    def test_legacy_timer_blocks_candidate(self):
        (self.root / "etc/systemd/system/boot-report.timer").write_text("OnCalendar=*-*-* 08:30:00\n")
        result, data = self.run_doctor()
        self.assertEqual(1, result.returncode)
        self.assertEqual("LEGACY_OR_DRIFT", data["classification"])

    def test_legacy_exec_blocks_candidate(self):
        (self.root / "etc/systemd/system/boot-report.service").write_text("ExecStart=/opt/boot-report/boot-report.sh\n")
        self.assertEqual("LEGACY_OR_DRIFT", self.run_doctor()[1]["classification"])

    def test_stale_or_missing_snapshot_not_ready(self):
        self.write_report(delay=2500)
        self.assertEqual("INCOMPLETE", self.run_doctor()[1]["classification"])
        self.report.unlink()
        self.assertEqual("MISSING", self.run_doctor()[1]["checks"]["snapshot"])

    def test_invalid_report(self):
        self.report.write_text("not-json")
        self.assertEqual("INVALID_REPORT", self.run_doctor()[1]["checks"]["snapshot"])


if __name__ == "__main__":
    unittest.main()
