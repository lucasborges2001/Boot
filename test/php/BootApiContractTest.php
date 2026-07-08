<?php

declare(strict_types=1);

/**
 * @file test/php/BootApiContractTest.php
 * @brief Verifica shape JSON estable y método GET en endpoints API Boot por CLI.
 */

$root = dirname(__DIR__, 2);
putenv('BOOT_REPORTS_DIR=' . $root . '/var/sample-reports');

function boot_api_contract_run_endpoint(string $path, string $method = 'GET'): array
{
    $_SERVER['REQUEST_METHOD'] = $method;
    $_GET = [];
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
assert($health['ok'] === true);
assert($health['module'] === 'boot');
assert($health['code'] === 'OK');
assert(isset($health['data']['health']));

$latest = boot_api_contract_run_endpoint($root . '/public_html/api/latest.php');
assert($latest['ok'] === true);
assert($latest['module'] === 'boot');
assert($latest['code'] === 'OK');
assert(isset($latest['data']['latest']));

$history = boot_api_contract_run_endpoint($root . '/public_html/api/history.php');
assert($history['ok'] === true);
assert($history['module'] === 'boot');
assert($history['code'] === 'OK');
assert(isset($history['data']['items']) && is_array($history['data']['items']));

$probe = boot_api_contract_run_endpoint($root . '/public_html/superadmin/api/probe.php');
assert($probe['ok'] === true);
assert($probe['module'] === 'boot');
assert($probe['code'] === 'OK');
assert(isset($probe['data']['health']));

$superHistory = boot_api_contract_run_endpoint($root . '/public_html/superadmin/api/history.php');
assert($superHistory['ok'] === true);
assert($superHistory['module'] === 'boot');
assert($superHistory['code'] === 'OK');
assert(isset($superHistory['data']['items']) && is_array($superHistory['data']['items']));

$superLatest = boot_api_contract_run_endpoint($root . '/public_html/superadmin/api/latest.php');
assert($superLatest['ok'] === true);
assert($superLatest['module'] === 'boot');
assert($superLatest['code'] === 'OK');
assert(isset($superLatest['data']['latest']));

$cmd = PHP_BINARY . ' -r ' . escapeshellarg('$_SERVER["REQUEST_METHOD"]="POST"; require ' . var_export($root . '/public_html/api/health.php', true) . ';');
$output = [];
$exitCode = 0;
exec($cmd, $output, $exitCode);
$methodPayload = json_decode(implode("
", $output), true);
assert(is_array($methodPayload));
assert($methodPayload['ok'] === false);
assert($methodPayload['module'] === 'boot');
assert($methodPayload['code'] === 'METHOD_NOT_ALLOWED');
assert($methodPayload['error']['message'] === 'Method not allowed. Use GET.');

echo "BootApiContractTest OK
";
