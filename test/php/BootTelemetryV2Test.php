<?php

declare(strict_types=1);

require_once __DIR__ . '/../../back/bootstrap.php';

$root = dirname(__DIR__, 2);
putenv('BOOT_REPORTS_DIR=' . $root . '/var/sample-reports');

$service = new BootStatusService();
$latest = $service->latest();
assert(is_array($latest));
assert($latest['schema_version'] === 2);
assert($latest['compatibility']['supported'] === true);
assert($latest['metrics']['cpu_used_percent'] === 31.4);
assert($latest['metrics']['swap_used_percent'] === 4.0);
assert(count($latest['filesystems']) === 2);
assert(count($latest['network_interfaces']) === 1);
assert($latest['artifacts']['report_json'] === 'latest/report.json');
assert($latest['server']['ip_wan'] === null);

$operational = $service->operationalSummary();
assert($operational['available'] === true);
assert($operational['server']['cpu_logical'] === 4);
assert($operational['metrics']['disk_root_used_percent'] === 72.0);

$cpu = $service->details('cpu');
$memory = $service->details('memory');
$filesystems = $service->details('filesystems');
$network = $service->details('network');
assert($cpu['data']['used_percent'] === 31.4);
assert($memory['data']['used_percent'] === 58.2);
assert(count($filesystems['data']) === 2);
assert($network['data'][0]['rate_status'] === 'ok');
assert($service->details('invalid') === null);

$history = (new BootHistoryService($root . '/var/sample-reports'))->recent(10);
assert(count($history) >= 1);
foreach ($history as $item) {
    assert(isset($item['snapshot_id']));
    assert(!isset($item['path']));
    assert(!str_starts_with($item['artifacts']['report_json'], '/'));
}

$common = (string)file_get_contents($root . '/public_html/api/_common.php');
assert(str_contains($common, 'Cache-Control: no-store'));
assert(str_contains($common, 'Boot telemetry is temporarily unavailable'));
foreach (glob($root . '/public_html/api/*.php') ?: [] as $endpoint) {
    $source = (string)file_get_contents($endpoint);
    assert(!str_contains($source, '$throwable->getMessage()'));
    assert(!str_contains($source, 'shell_exec'));
    assert(!str_contains($source, 'proc_open'));
}

echo "BootTelemetryV2Test OK\n";
