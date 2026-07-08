<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/api/history.php
 * @brief Proxy read-only del historial Boot para SuperAdmin.
 */

require_once __DIR__ . '/_common.php';

$bootApiMethod = $_SERVER['REQUEST_METHOD'] ?? 'GET';
boot_api_require_method('GET', $bootApiMethod);

try {
    boot_api_send_ok(['items' => (new BootHistoryService())->recent(10)], 'OK');
} catch (Throwable $throwable) {
    boot_api_send_error('INTERNAL_ERROR', $throwable->getMessage(), 500);
}
