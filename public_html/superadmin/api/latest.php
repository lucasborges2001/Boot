<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/api/latest.php
 * @brief Proxy read-only del último snapshot Boot para la vista SuperAdmin.
 */

require_once __DIR__ . '/_common.php';

boot_api_require_get();

try {
    $latest = (new BootStatusService())->latest();
    if ($latest === null) {
        boot_api_error('boot.latest.missing', 'No Boot snapshot available', 404);
        return;
    }

    boot_api_ok('boot.latest.ok', ['latest' => $latest]);
} catch (Throwable $throwable) {
    boot_api_error('boot.latest.error', $throwable->getMessage(), 500);
}
