<?php

declare(strict_types=1);

/**
 * @file public_html/api/health.php
 * @brief Expone el estado read-only del último snapshot Boot con contrato JSON estable.
 */

require_once __DIR__ . '/_common.php';

boot_api_require_get();

try {
    $health = (new BootStatusService())->health();
    boot_api_ok('boot.health.ok', ['health' => $health]);
} catch (Throwable $throwable) {
    boot_api_error('boot.health.error', $throwable->getMessage(), 500);
}
