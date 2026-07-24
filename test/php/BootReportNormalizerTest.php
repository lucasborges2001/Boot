<?php

declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';

boot_test_run('BootReportNormalizerTest', static function (): void {
    $root = dirname(__DIR__, 2);
    $normalizer = new BootReportNormalizer();

    $v2 = boot_test_json_file($root . '/var/sample-reports/latest/report.json');
    $v2Api = $normalizer->normalizeForApi($v2);
    boot_test_same('boot', $v2Api['module'] ?? null, 'Unexpected v2 module');
    boot_test_same(2, $v2Api['schema_version'] ?? null, 'Unexpected v2 schema');
    boot_test_same(true, $v2Api['compatibility']['supported'] ?? null, 'v2 must be supported');
    boot_test_same(false, $v2Api['compatibility']['legacy_v1'] ?? null, 'v2 cannot be legacy');
    boot_test_assert(isset($v2Api['cpu']['used_percent']), 'v2 CPU detail missing');
    boot_test_assert(isset($v2Api['memory']['total_bytes']), 'v2 memory detail missing');
    boot_test_same(2, count($v2Api['filesystems'] ?? []), 'Unexpected filesystem fixture count');
    boot_test_same(1, count($v2Api['network_interfaces'] ?? []), 'Unexpected interface fixture count');
    boot_test_same(null, $v2Api['server']['ip_wan'] ?? null, 'Public WAN IP must remain null');
    boot_test_same('latest/report.json', $v2Api['artifacts']['report_json'] ?? null, 'Artifact path must be relative');
    boot_test_assert(isset($v2Api['base_snapshot']), 'Base snapshot missing');

    $v1 = boot_test_json_file($root . '/var/sample-reports/v1/report.json');
    $v1Api = $normalizer->normalizeForApi($v1);
    boot_test_same(1, $v1Api['schema_version'] ?? null, 'Unexpected v1 schema');
    boot_test_same(true, $v1Api['compatibility']['supported'] ?? null, 'v1 must remain supported');
    boot_test_same(true, $v1Api['compatibility']['legacy_v1'] ?? null, 'v1 must be marked legacy');
    boot_test_same(47.5, $v1Api['metrics']['ram_used_percent'] ?? null, 'v1 RAM metric changed');
    boot_test_same([], $v1Api['cpu'] ?? null, 'v1 CPU extension must normalize empty');
    boot_test_same([], $v1Api['network_interfaces'] ?? null, 'v1 network extension must normalize empty');
});
