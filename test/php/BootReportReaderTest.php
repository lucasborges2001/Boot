<?php

declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';

boot_test_run('BootReportReaderTest', static function (): void {
    $root = dirname(__DIR__, 2);
    $reader = new BootReportReader($root . '/var/sample-reports/latest/report.json');
    $snapshot = $reader->latest();
    boot_test_assert($snapshot instanceof MetricSnapshot, 'Expected MetricSnapshot from v2 fixture');
    boot_test_same('boot', $snapshot->source(), 'Unexpected snapshot source');
});
