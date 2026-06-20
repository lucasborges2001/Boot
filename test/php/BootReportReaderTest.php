<?php

declare(strict_types=1);
require_once __DIR__ . '/../../back/bootstrap.php';
$reader = new BootReportReader(__DIR__ . '/../../var/sample-reports/latest/report.json');
$snapshot = $reader->latest();
assert($snapshot instanceof MetricSnapshot);
assert($snapshot->source() === 'boot');
echo "BootReportReaderTest OK\n";
