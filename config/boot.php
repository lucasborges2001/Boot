<?php

declare(strict_types=1);
return [
    'module' => 'boot',
    'schema_version' => 1,
    'reports_dir' => getenv('BOOT_REPORTS_DIR') ?: '/var/lib/boot-report/reports',
    'retention_days' => (int)(getenv('BOOT_RETENTION_DAYS') ?: 14),
    'send_telegram' => !in_array(strtolower((string)(getenv('BOOT_SEND_TELEGRAM') ?: 'true')), ['0','false','no','off'], true),
];
