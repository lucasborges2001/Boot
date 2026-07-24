#!/usr/bin/env python3
"""Apply the optional Telegram send result to an existing Boot report."""

import json
import os


def parse_bool_or_none(value: object):
    normalized = str(value).strip().lower()
    if normalized in ("true", "1", "yes", "on"):
        return True
    if normalized in ("false", "0", "no", "off"):
        return False
    return None


def main() -> None:
    try:
        data = json.loads(os.environ.get("BOOT_REPORT_JSON", "{}"))
    except (TypeError, ValueError, json.JSONDecodeError):
        data = {}

    telegram = data.get("telegram") if isinstance(data.get("telegram"), dict) else {}
    telegram["enabled"] = bool(
        parse_bool_or_none(os.environ.get("BOOT_TELEGRAM_ENABLED_VALUE", "false"))
    )
    telegram["last_send_ok"] = parse_bool_or_none(
        os.environ.get("BOOT_TELEGRAM_OK_VALUE", "null")
    )

    message_id = os.environ.get("BOOT_TELEGRAM_MESSAGE_ID_VALUE", "null")
    try:
        telegram["message_id"] = int(message_id) if message_id not in ("", "null", "None") else None
    except ValueError:
        telegram["message_id"] = None

    telegram["description"] = os.environ.get("BOOT_TELEGRAM_DESCRIPTION_VALUE", "") or None
    data["telegram"] = telegram
    print(json.dumps(data, ensure_ascii=False, separators=(",", ":")))


if __name__ == "__main__":
    main()
