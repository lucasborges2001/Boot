<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/api/summary.php
 * @brief Resumen operativo read-only para consumidores SuperAdmin.
 */

require_once __DIR__ . '/_common.php';

boot_api_require_get();

try {
    boot_api_send_ok([
        'summary' => (new BootStatusService())->operationalSummary(),
    ]);
} catch (Throwable $throwable) {
    boot_api_internal_error();
}
