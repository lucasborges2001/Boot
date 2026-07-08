<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/api/latest.php
 * @brief Proxy read-only del último snapshot Boot para la vista SuperAdmin.
 */

require_once __DIR__ . '/_common.php';

$bootApiMethod = $_SERVER['REQUEST_METHOD'] ?? 'GET';
boot_api_require_method('GET', $bootApiMethod);

try {
    $latest = (new BootStatusService())->latest();
    if ($latest === null) {
        boot_api_send_error('NO_SNAPSHOT', 'No Boot snapshot available', 404);
        return;
    }

    boot_api_send_ok(['latest' => $latest], 'OK');
} catch (Throwable $throwable) {
    boot_api_send_error('INTERNAL_ERROR', $throwable->getMessage(), 500);
}
