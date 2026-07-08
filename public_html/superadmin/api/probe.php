<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/api/probe.php
 * @brief Probe read-only de disponibilidad para la pantalla SuperAdmin de Boot.
 */

require_once __DIR__ . '/_common.php';

$bootApiMethod = $_SERVER['REQUEST_METHOD'] ?? 'GET';
boot_api_require_method('GET', $bootApiMethod);

try {
    boot_api_send_ok(['health' => (new BootStatusService())->health()], 'OK');
} catch (Throwable $throwable) {
    boot_api_send_error('INTERNAL_ERROR', $throwable->getMessage(), 500);
}
