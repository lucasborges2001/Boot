<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/api/latest.php
 * @brief Expone el último snapshot Boot read-only para la vista SuperAdmin.
 */

require_once __DIR__ . '/_common.php';

boot_api_require_get();

try {
    $latest = (new BootStatusService())->latest();
    if ($latest === null) {
        boot_api_send_error('NO_SNAPSHOT', 'No Boot snapshot available', 404);
        return;
    }

    boot_api_send_ok(['latest' => $latest]);
} catch (Throwable $throwable) {
    boot_api_internal_error();
}
