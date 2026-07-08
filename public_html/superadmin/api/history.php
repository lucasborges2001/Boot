<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/api/history.php
 * @brief Proxy read-only del historial Boot para SuperAdmin.
 */

require_once __DIR__ . '/_common.php';

boot_api_require_get();

try {
    boot_api_ok('boot.history.ok', ['items' => (new BootHistoryService())->recent(10)]);
} catch (Throwable $throwable) {
    boot_api_error('boot.history.error', $throwable->getMessage(), 500);
}
