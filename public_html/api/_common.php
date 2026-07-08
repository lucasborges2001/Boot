<?php

declare(strict_types=1);

/**
 * @file public_html/api/_common.php
 * @brief Helpers compartidos para endpoints read-only JSON del módulo Boot.
 */

require_once __DIR__ . '/../../back/bootstrap.php';

function boot_api_request_method(): string
{
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    return strtoupper((string)($method !== '' ? $method : 'GET'));
}

function boot_api_send_headers(int $status, array $extraHeaders = []): void
{
    http_response_code($status);
    if (PHP_SAPI === 'cli') {
        return;
    }
    if (!headers_sent()) {
        header('Content-Type: application/json; charset=utf-8');
        foreach ($extraHeaders as $header) {
            header($header);
        }
    }
}

function boot_api_payload(bool $ok, string $code, array $data = [], ?string $error = null): array
{
    $payload = [
        'ok' => $ok,
        'module' => BOOT_MODULE_NAME,
        'code' => $code,
    ];

    if ($ok) {
        $payload['data'] = $data;
    } else {
        $payload['error'] = $error ?? 'Boot API error';
        if ($data !== []) {
            $payload['data'] = $data;
        }
    }

    return $payload;
}

function boot_api_json(array $payload, int $status = 200, array $headers = []): void
{
    boot_api_send_headers($status, $headers);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
}

function boot_api_ok(string $code, array $data = [], int $status = 200): void
{
    boot_api_json(boot_api_payload(true, $code, $data), $status);
}

function boot_api_error(string $code, string $error, int $status = 400, array $data = [], array $headers = []): void
{
    boot_api_json(boot_api_payload(false, $code, $data, $error), $status, $headers);
}

function boot_api_require_get(): void
{
    if (boot_api_request_method() !== 'GET') {
        boot_api_error(
            'boot.http.method_not_allowed',
            'Method not allowed. Use GET.',
            405,
            [],
            ['Allow: GET']
        );
        exit;
    }
}

function boot_api_limit_from_query(int $default = 10, int $min = 1, int $max = 50): int
{
    $raw = $_GET['limit'] ?? $default;
    $limit = is_numeric($raw) ? (int)$raw : $default;
    return max($min, min($max, $limit));
}
