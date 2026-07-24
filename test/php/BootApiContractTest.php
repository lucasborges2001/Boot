<?php

declare(strict_types=1);

/**
 * @file test/php/BootApiContractTest.php
 * @brief Verifica shape JSON estable y método GET en endpoints API Boot por CLI.
 */

$root = dirname(__DIR__, 2);
putenv('BOOT_REPORTS_DIR=' . $root . '/var/sample-reports');

function boot_api_contract_run_endpoint(string $path, string $method = 'GET', array $query = []): array
{
    $_SERVER['REQUEST_METHOD'] = $method;
    $_GET = $query;
    ob_start();
    require $path;
    $json = ob_get_clean();
    $payload = json_decode((string)$json, true);

    assert(is_array($payload), 'Endpoint did not return JSON object: ' . $path);
    assert(array_key_exists('ok', $payload));
    assert(($payload['module'] ?? null) === 'boot');
    assert(isset($payload['code']) && is_string($payload['code']));

    if (($payload['ok'] ?? null) === true) {
        assert($payload['code'] === 'OK');
        assert(isset($payload['data']) && is_array($payload['data']));
    } else {
        assert(isset($payload['error']['message']) && is_string($payload['error']['message']));
    }

    return $payload;
}

$health = boot_api_contract_run_endpoint($root . '/public_html/api/health.php');
assert(isset($health['data']['health']));
assert(!isset($health['data']['health']['latest_path']));

$latest = boot_api_contract_run_endpoint($root . '/public_html/api/latest.php');
assert(isset($latest['data']['latest']));
assert($latest['data']['latest']['schema_version'] === 2);
assert($latest['data']['latest']['artifacts']['report_json'] === 'latest/report.json');

$history = boot_api_contract_run_endpoint($root . '/public_html/api/history.php');
assert(isset($history['data']['items']) && is_array($history['data']['items']));
foreach ($history['data']['items'] as $item) {
    assert(!isset($item['path']));
    assert(isset($item['snapshot_id']));
}

$summary = boot_api_contract_run_endpoint($root . '/public_html/api/summary.php');
assert(isset($summary['data']['summary']['metrics']));

$details = boot_api_contract_run_endpoint(
    $root . '/public_html/api/details.php',
    'GET',
    ['section' => 'network']
);
assert($details['data']['details']['section'] === 'network');
assert(is_array($details['data']['details']['data']));

$invalidDetails = boot_api_contract_run_endpoint(
    $root . '/public_html/api/details.php',
    'GET',
    ['section' => 'invalid']
);
assert($invalidDetails['ok'] === false);
assert($invalidDetails['code'] === 'INVALID_SECTION');

$probe = boot_api_contract_run_endpoint($root . '/public_html/superadmin/api/probe.php');
assert(isset($probe['data']['health']));

$superHistory = boot_api_contract_run_endpoint($root . '/public_html/superadmin/api/history.php');
assert(isset($superHistory['data']['items']) && is_array($superHistory['data']['items']));

$superLatest = boot_api_contract_run_endpoint($root . '/public_html/superadmin/api/latest.php');
assert(isset($superLatest['data']['latest']));

$superSummary = boot_api_contract_run_endpoint($root . '/public_html/superadmin/api/summary.php');
assert(isset($superSummary['data']['summary']));

$superDetails = boot_api_contract_run_endpoint(
    $root . '/public_html/superadmin/api/details.php',
    'GET',
    ['section' => 'cpu']
);
assert($superDetails['data']['details']['section'] === 'cpu');

$cmd = PHP_BINARY . ' -r ' . escapeshellarg('$_SERVER["REQUEST_METHOD"]="POST"; require ' . var_export($root . '/public_html/api/health.php', true) . ';');
$output = [];
$exitCode = 0;
exec($cmd, $output, $exitCode);
$methodPayload = json_decode(implode("\n", $output), true);
assert(is_array($methodPayload));
assert($methodPayload['ok'] === false);
assert($methodPayload['module'] === 'boot');
assert($methodPayload['code'] === 'METHOD_NOT_ALLOWED');
assert($methodPayload['error']['message'] === 'Method not allowed. Use GET.');

echo "BootApiContractTest OK\n";
