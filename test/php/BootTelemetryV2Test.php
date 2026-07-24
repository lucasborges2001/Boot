<?php

declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';

boot_test_run('BootTelemetryV2Test', static function (): void {
    $root = dirname(__DIR__, 2);
    putenv('BOOT_REPORTS_DIR=' . $root . '/var/sample-reports');
    putenv('BOOT_ALLOW_SAMPLE_REPORTS=false');

    $service = new BootStatusService();
    $latest = $service->latest();
    boot_test_assert(is_array($latest), 'Expected v2 fixture snapshot');
    boot_test_same(2, $latest['schema_version'] ?? null, 'Unexpected v2 schema');
    boot_test_same(true, $latest['compatibility']['supported'] ?? null, 'v2 must be supported');
    boot_test_same(31.4, $latest['metrics']['cpu_used_percent'] ?? null, 'Unexpected CPU metric');
    boot_test_same(4.0, $latest['metrics']['swap_used_percent'] ?? null, 'Unexpected swap metric');
    boot_test_same(2, count($latest['filesystems'] ?? []), 'Unexpected filesystem count');
    boot_test_same(1, count($latest['network_interfaces'] ?? []), 'Unexpected network count');
    boot_test_same('latest/report.json', $latest['artifacts']['report_json'] ?? null, 'Artifact path leaked');
    boot_test_same(null, $latest['server']['ip_wan'] ?? null, 'WAN IP must remain null');

    $operational = $service->operationalSummary();
    boot_test_same(true, $operational['available'] ?? null, 'Operational summary unavailable');
    boot_test_same(4, $operational['server']['cpu_logical'] ?? null, 'Unexpected logical CPU count');
    boot_test_same(72.0, $operational['metrics']['disk_root_used_percent'] ?? null, 'Unexpected root usage');

    $cpu = $service->details('cpu');
    $memory = $service->details('memory');
    $filesystems = $service->details('filesystems');
    $network = $service->details('network');
    boot_test_same(31.4, $cpu['data']['used_percent'] ?? null, 'CPU details changed');
    boot_test_same(58.2, $memory['data']['used_percent'] ?? null, 'Memory details changed');
    boot_test_same(2, count($filesystems['data'] ?? []), 'Filesystem details changed');
    boot_test_same('ok', $network['data'][0]['rate_status'] ?? null, 'Network rate fixture changed');
    boot_test_same(null, $service->details('invalid'), 'Invalid detail section must be rejected');

    $history = (new BootHistoryService($root . '/var/sample-reports'))->recent(10);
    boot_test_assert(count($history) >= 1, 'Expected explicit sample history');
    foreach ($history as $item) {
        boot_test_assert(isset($item['snapshot_id']), 'History snapshot_id missing');
        boot_test_assert(!isset($item['path']), 'History leaked absolute path');
        boot_test_assert(!str_starts_with((string)($item['artifacts']['report_json'] ?? '/'), '/'), 'History artifact path must be relative');
    }

    $missing = sys_get_temp_dir() . '/boot-missing-' . bin2hex(random_bytes(6));
    putenv('BOOT_REPORTS_DIR=' . $missing);
    putenv('BOOT_ALLOW_SAMPLE_REPORTS=false');
    $missingService = new BootStatusService();
    boot_test_same(null, $missingService->latest(), 'Missing runtime snapshot must not use fixture implicitly');
    boot_test_same(false, $missingService->health()['snapshot_available'] ?? null, 'Missing snapshot health incorrect');
    boot_test_same([], (new BootHistoryService($missing))->recent(10), 'Missing history must remain empty');

    $common = (string)file_get_contents($root . '/public_html/api/_common.php');
    boot_test_assert(str_contains($common, 'Cache-Control: no-store'), 'No-store header missing');
    boot_test_assert(str_contains($common, 'Boot telemetry is temporarily unavailable'), 'Generic internal error missing');
    $apiFiles = array_merge(
        glob($root . '/public_html/api/*.php') ?: [],
        glob($root . '/public_html/superadmin/api/*.php') ?: []
    );
    foreach ($apiFiles as $endpoint) {
        $source = (string)file_get_contents($endpoint);
        boot_test_assert(!str_contains($source, '$throwable->getMessage()'), 'Endpoint leaks throwable: ' . $endpoint);
        boot_test_assert(!str_contains($source, 'shell_exec'), 'Endpoint executes shell: ' . $endpoint);
        boot_test_assert(!str_contains($source, 'proc_open'), 'Endpoint opens process: ' . $endpoint);
    }
});
