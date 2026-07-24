<?php

declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';

boot_test_run('BootStatusServiceTest', static function (): void {
    $root = dirname(__DIR__, 2);
    putenv('BOOT_REPORTS_DIR=' . $root . '/var/sample-reports');
    putenv('BOOT_ALLOW_SAMPLE_REPORTS=false');

    $service = new BootStatusService();
    $health = $service->health();
    boot_test_same('boot', $health['module'] ?? null, 'Unexpected health module');
    boot_test_assert(isset($health['severity']), 'Health severity missing');
    boot_test_same(true, $health['snapshot_available'] ?? null, 'Fixture snapshot must be available');
    boot_test_assert(!array_key_exists('latest_path', $health), 'Health must not expose internal path');
});
