<?php

declare(strict_types=1);
require_once __DIR__ . '/../../back/bootstrap.php';
$raw = json_decode((string)file_get_contents(__DIR__ . '/../../var/sample-reports/latest/report.json'), true);
$normalizer = new BootReportNormalizer();
$api = $normalizer->normalizeForApi($raw);
assert($api['module'] === 'boot');
assert(isset($api['base_snapshot']));
echo "BootReportNormalizerTest OK\n";
