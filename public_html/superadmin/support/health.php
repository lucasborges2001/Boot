<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/support/health.php
 * @brief Normaliza el estado Boot para la cabecera y tarjetas de SuperAdmin.
 */

require_once __DIR__ . '/../../../back/bootstrap.php';

if (!function_exists('boot_superadmin_health_view_model')) {
    function boot_superadmin_health_view_model(?BootStatusService $service = null, ?array $summary = null): array
    {
        $service = $service ?: new BootStatusService();
        $health = is_array($summary['health'] ?? null) ? $summary['health'] : $service->health();

        return [
            'ok' => (bool)($health['ok'] ?? false),
            'module' => (string)($health['module'] ?? BOOT_MODULE_NAME),
            'severity' => (string)($health['severity'] ?? 'unknown'),
            'summary' => (string)($health['summary'] ?? 'Sin estado'),
            'generated_at' => (string)($health['generated_at'] ?? 'n/a'),
            'latest_path' => (string)($health['latest_path'] ?? ''),
        ];
    }
}
