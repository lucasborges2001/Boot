<?php

declare(strict_types=1);

require_once __DIR__ . '/../../back/bootstrap.php';

$normalizer = new BootReportNormalizer();

$v2 = json_decode((string)file_get_contents(__DIR__ . '/../../var/sample-reports/latest/report.json'), true);
assert(is_array($v2));
$v2Api = $normalizer->normalizeForApi($v2);
assert($v2Api['module'] === 'boot');
assert($v2Api['schema_version'] === 2);
assert($v2Api['compatibility']['supported'] === true);
assert($v2Api['compatibility']['legacy_v1'] === false);
assert(isset($v2Api['cpu']['used_percent']));
assert(isset($v2Api['memory']['total_bytes']));
assert(count($v2Api['filesystems']) === 2);
assert(count($v2Api['network_interfaces']) === 1);
assert($v2Api['server']['ip_wan'] === null);
assert($v2Api['artifacts']['report_json'] === 'latest/report.json');
assert(!str_starts_with($v2Api['artifacts']['report_json'], '/'));
assert(isset($v2Api['base_snapshot']));

$v1 = json_decode((string)file_get_contents(__DIR__ . '/../../var/sample-reports/v1/report.json'), true);
assert(is_array($v1));
$v1Api = $normalizer->normalizeForApi($v1);
assert($v1Api['schema_version'] === 1);
assert($v1Api['compatibility']['supported'] === true);
assert($v1Api['compatibility']['legacy_v1'] === true);
assert($v1Api['metrics']['ram_used_percent'] === 47.5);
assert($v1Api['cpu'] === []);
assert($v1Api['network_interfaces'] === []);

echo "BootReportNormalizerTest OK\n";
