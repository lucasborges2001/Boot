<?php

declare(strict_types=1);

/**
 * @file public_html/api/_common.php
 * @brief Helpers compartidos para endpoints read-only JSON del módulo Boot.
 */

require_once __DIR__ . '/../../back/bootstrap.php';

if (!function_exists('boot_api_request_method')) {
    function boot_api_request_method(?string $method = null): string
    {
        $method = $method ?? ($_SERVER['REQUEST_METHOD'] ?? 'GET');
        $method = strtoupper(trim((string)$method));
        return $method !== '' ? $method : 'GET';
    }
}

if (!function_exists('boot_api_send_headers')) {
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
}

if (!function_exists('boot_api_success_payload')) {
    function boot_api_success_payload(array $data = [], string $code = 'OK'): array
    {
        return [
            'ok' => true,
            'module' => BOOT_MODULE_NAME,
            'code' => $code,
            'data' => $data,
        ];
    }
}

if (!function_exists('boot_api_error_payload')) {
    function boot_api_error_payload(string $code, string $message, array $data = []): array
    {
        $payload = [
            'ok' => false,
            'module' => BOOT_MODULE_NAME,
            'code' => $code,
            'error' => [
                'message' => $message,
            ],
        ];

        if ($data !== []) {
            $payload['data'] = $data;
        }

        return $payload;
    }
}

if (!function_exists('boot_api_send_json')) {
    function boot_api_send_json(array $payload, int $status = 200, array $headers = []): void
    {
        boot_api_send_headers($status, $headers);
        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
    }
}

if (!function_exists('boot_api_send_ok')) {
    function boot_api_send_ok(array $data = [], string $code = 'OK', int $status = 200): void
    {
        boot_api_send_json(boot_api_success_payload($data, $code), $status);
    }
}

if (!function_exists('boot_api_send_error')) {
    function boot_api_send_error(
        string $code,
        string $message,
        int $status = 400,
        array $data = [],
        array $headers = []
    ): void {
        boot_api_send_json(boot_api_error_payload($code, $message, $data), $status, $headers);
    }
}

if (!function_exists('boot_api_require_method')) {
    function boot_api_require_method(string $allowedMethod, ?string $actualMethod = null): void
    {
        $allowedMethod = strtoupper(trim($allowedMethod));
        $actualMethod = boot_api_request_method($actualMethod);

        if ($actualMethod !== $allowedMethod) {
            boot_api_send_error(
                'METHOD_NOT_ALLOWED',
                'Method not allowed. Use ' . $allowedMethod . '.',
                405,
                [],
                ['Allow: ' . $allowedMethod]
            );
            exit;
        }
    }
}

if (!function_exists('boot_api_require_get')) {
    function boot_api_require_get(?string $actualMethod = null): void
    {
        boot_api_require_method('GET', $actualMethod);
    }
}

if (!function_exists('boot_api_ok')) {
    function boot_api_ok(string $code, array $data = [], int $status = 200): void
    {
        boot_api_send_ok($data, $code, $status);
    }
}

if (!function_exists('boot_api_error')) {
    function boot_api_error(string $code, string $error, int $status = 400, array $data = [], array $headers = []): void
    {
        boot_api_send_error($code, $error, $status, $data, $headers);
    }
}

if (!function_exists('boot_api_limit_from_query')) {
    function boot_api_limit_from_query(int $default = 10, int $min = 1, int $max = 50): int
    {
        $raw = $_GET['limit'] ?? $default;
        $limit = is_numeric($raw) ? (int)$raw : $default;
        return max($min, min($max, $limit));
    }
}
