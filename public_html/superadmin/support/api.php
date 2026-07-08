<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/support/api.php
 * @brief Adaptadores legacy de respuesta JSON para código SuperAdmin Boot anterior al helper común.
 */

require_once __DIR__ . '/../api/_common.php';

if (!function_exists('boot_superadmin_json')) {
    function boot_superadmin_json(array $payload, int $status = 200): void
    {
        boot_api_send_json($payload, $status);
    }
}

if (!function_exists('boot_superadmin_json_ok')) {
    function boot_superadmin_json_ok(array $data = [], string $code = 'OK', int $status = 200): void
    {
        boot_api_send_ok($data, $code, $status);
    }
}

if (!function_exists('boot_superadmin_json_error')) {
    function boot_superadmin_json_error(string $code, string $message, int $status = 400): void
    {
        boot_api_send_error($code, $message, $status);
    }
}
