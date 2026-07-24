<?php

declare(strict_types=1);

require_once __DIR__ . '/../../back/bootstrap.php';

function boot_test_assert(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
}

function boot_test_same($expected, $actual, string $message): void
{
    if ($expected !== $actual) {
        throw new RuntimeException(
            $message . ' expected=' . var_export($expected, true) . ' actual=' . var_export($actual, true)
        );
    }
}

function boot_test_json_file(string $path): array
{
    $contents = file_get_contents($path);
    boot_test_assert(is_string($contents), 'Unable to read fixture: ' . $path);
    $decoded = json_decode($contents, true);
    boot_test_assert(is_array($decoded), 'Fixture is not a JSON object: ' . $path);
    return $decoded;
}

function boot_test_run(string $name, callable $test): void
{
    try {
        $test();
        echo $name . " OK\n";
    } catch (Throwable $throwable) {
        fwrite(STDERR, $name . ' FAIL: ' . $throwable->getMessage() . "\n");
        exit(1);
    }
}
