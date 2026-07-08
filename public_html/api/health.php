<?php

declare(strict_types=1);

/**
 * @file public_html/api/health.php
 * @brief Expone el estado read-only del último snapshot Boot con contrato JSON estable.
 */

require_once __DIR__ . '/_common.php';

$bootApiMethod = $_SERVER['REQUEST_METHOD'] ?? 'GET';
boot_api_require_method('GET', $bootApiMethod);

try {
    $health = (new BootStatusService())->health();
    boot_api_send_ok(['health' => $health], 'OK');
} catch (Throwable $throwable) {
    boot_api_send_error('INTERNAL_ERROR', $throwable->getMessage(), 500);
}
