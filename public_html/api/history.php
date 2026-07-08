<?php

declare(strict_types=1);

/**
 * @file public_html/api/history.php
 * @brief Lista snapshots históricos Boot de forma read-only con límite acotado.
 */

require_once __DIR__ . '/_common.php';

$bootApiMethod = $_SERVER['REQUEST_METHOD'] ?? 'GET';
boot_api_require_method('GET', $bootApiMethod);

try {
    $limit = boot_api_limit_from_query(10, 1, 50);
    boot_api_send_ok(['items' => (new BootHistoryService())->recent($limit)], 'OK');
} catch (Throwable $throwable) {
    boot_api_send_error('INTERNAL_ERROR', $throwable->getMessage(), 500);
}
