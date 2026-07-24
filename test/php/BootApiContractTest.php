<?php

declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';

function boot_api_contract_run_endpoint(string $path, string $method = 'GET', array $query = []): array
{
    $_SERVER['REQUEST_METHOD'] = $method;
    $_GET = $query;
    ob_start();
    require $path;
    $json = ob_get_clean();
    $payload = json_decode((string)$json, true);

    boot_test_assert(is_array($payload), 'Endpoint did not return JSON object: ' . $path);
    boot_test_assert(array_key_exists('ok', $payload), 'Endpoint ok field missing: ' . $path);
    boot_test_same('boot', $payload['module'] ?? null, 'Endpoint module changed: ' . $path);
    boot_test_assert(isset($payload['code']) && is_string($payload['code']), 'Endpoint code missing: ' . $path);

    if (($payload['ok'] ?? null) === true) {
        boot_test_same('OK', $payload['code'], 'Unexpected success code: ' . $path);
        boot_test_assert(isset($payload['data']) && is_array($payload['data']), 'Success data missing: ' . $path);
    } else {
        boot_test_assert(isset($payload['error']['message']) && is_string($payload['error']['message']), 'Error message missing: ' . $path);
    }

    return $payload;
}

boot_test_run('BootApiContractTest', static function (): void {
    $root = dirname(__DIR__, 2);
    putenv('BOOT_REPORTS_DIR=' . $root . '/var/sample-reports');
    putenv('BOOT_ALLOW_SAMPLE_REPORTS=false');

    $health = boot_api_contract_run_endpoint($root . '/public_html/api/health.php');
    boot_test_assert(isset($health['data']['health']), 'Health payload missing');
    boot_test_assert(!isset($health['data']['health']['latest_path']), 'Health leaked latest path');

    $latest = boot_api_contract_run_endpoint($root . '/public_html/api/latest.php');
    boot_test_assert(isset($latest['data']['latest']), 'Latest payload missing');
    boot_test_same(2, $latest['data']['latest']['schema_version'] ?? null, 'Unexpected latest schema');
    boot_test_same('latest/report.json', $latest['data']['latest']['artifacts']['report_json'] ?? null, 'Latest artifact path leaked');

    $history = boot_api_contract_run_endpoint($root . '/public_html/api/history.php');
    boot_test_assert(isset($history['data']['items']) && is_array($history['data']['items']), 'History items missing');
    foreach ($history['data']['items'] as $item) {
        boot_test_assert(!isset($item['path']), 'History leaked path');
        boot_test_assert(isset($item['snapshot_id']), 'History snapshot_id missing');
    }

    $summary = boot_api_contract_run_endpoint($root . '/public_html/api/summary.php');
    boot_test_assert(isset($summary['data']['summary']['metrics']), 'Operational summary metrics missing');

    $details = boot_api_contract_run_endpoint(
        $root . '/public_html/api/details.php',
        'GET',
        ['section' => 'network']
    );
    boot_test_same('network', $details['data']['details']['section'] ?? null, 'Network details section changed');
    boot_test_assert(is_array($details['data']['details']['data'] ?? null), 'Network details data missing');

    $invalidDetails = boot_api_contract_run_endpoint(
        $root . '/public_html/api/details.php',
        'GET',
        ['section' => 'invalid']
    );
    boot_test_same(false, $invalidDetails['ok'] ?? null, 'Invalid section must fail');
    boot_test_same('INVALID_SECTION', $invalidDetails['code'] ?? null, 'Invalid section code changed');

    $probe = boot_api_contract_run_endpoint($root . '/public_html/superadmin/api/probe.php');
    boot_test_assert(isset($probe['data']['health']), 'SuperAdmin probe health missing');

    $superHistory = boot_api_contract_run_endpoint($root . '/public_html/superadmin/api/history.php');
    boot_test_assert(isset($superHistory['data']['items']) && is_array($superHistory['data']['items']), 'SuperAdmin history missing');

    $superLatest = boot_api_contract_run_endpoint($root . '/public_html/superadmin/api/latest.php');
    boot_test_assert(isset($superLatest['data']['latest']), 'SuperAdmin latest missing');

    $superSummary = boot_api_contract_run_endpoint($root . '/public_html/superadmin/api/summary.php');
    boot_test_assert(isset($superSummary['data']['summary']), 'SuperAdmin summary missing');

    $superDetails = boot_api_contract_run_endpoint(
        $root . '/public_html/superadmin/api/details.php',
        'GET',
        ['section' => 'cpu']
    );
    boot_test_same('cpu', $superDetails['data']['details']['section'] ?? null, 'SuperAdmin CPU details changed');

    $inline = '$_SERVER["REQUEST_METHOD"]="POST"; require ' . var_export($root . '/public_html/api/health.php', true) . ';';
    $cmd = escapeshellarg(PHP_BINARY) . ' -r ' . escapeshellarg($inline);
    $output = [];
    $exitCode = 0;
    exec($cmd, $output, $exitCode);
    boot_test_same(0, $exitCode, 'POST method subprocess failed unexpectedly');
    $methodPayload = json_decode(implode("\n", $output), true);
    boot_test_assert(is_array($methodPayload), 'POST response is not JSON');
    boot_test_same(false, $methodPayload['ok'] ?? null, 'POST must fail');
    boot_test_same('boot', $methodPayload['module'] ?? null, 'POST module changed');
    boot_test_same('METHOD_NOT_ALLOWED', $methodPayload['code'] ?? null, 'POST error code changed');
    boot_test_same('Method not allowed. Use GET.', $methodPayload['error']['message'] ?? null, 'POST error message changed');
});
