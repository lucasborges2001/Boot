<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/api/history.php
 * @brief Expone historial Boot read-only para SuperAdmin.
 */

require_once __DIR__ . '/_common.php';

boot_api_require_get();

try {
    $limit = boot_api_limit_from_query(10, 1, 50);
    boot_api_send_ok([
        'items' => (new BootHistoryService())->recent($limit),
    ]);
} catch (Throwable $throwable) {
    boot_api_internal_error();
}
