<?php

declare(strict_types=1);

/**
 * @file public_html/api/history.php
 * @brief Lista snapshots históricos Boot de forma read-only con límite acotado.
 */

require_once __DIR__ . '/_common.php';

boot_api_require_get();

try {
    $limit = boot_api_limit_from_query(10, 1, 50);
    boot_api_ok('boot.history.ok', ['items' => (new BootHistoryService())->recent($limit)]);
} catch (Throwable $throwable) {
    boot_api_error('boot.history.error', $throwable->getMessage(), 500);
}
