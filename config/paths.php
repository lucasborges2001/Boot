<?php

declare(strict_types=1);
$reportsDir = getenv('BOOT_REPORTS_DIR') ?: '/var/lib/boot-report/reports';
return [
    'reports_dir' => $reportsDir,
    'latest_report' => $reportsDir . '/latest/report.json',
    'latest_summary' => $reportsDir . '/latest/summary.txt',
];
