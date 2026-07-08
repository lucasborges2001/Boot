<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/api/probe.php
 * @brief Probe read-only de disponibilidad para la pantalla SuperAdmin de Boot.
 */

require_once __DIR__ . '/_common.php';

boot_api_require_get();

try {
    boot_api_ok('boot.probe.ok', ['health' => (new BootStatusService())->health()]);
} catch (Throwable $throwable) {
    boot_api_error('boot.probe.error', $throwable->getMessage(), 500);
}
