<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/support/metrics.php
 * @brief Construye view models de snapshot, métricas e historial para SuperAdmin Boot.
 */

require_once __DIR__ . '/../../../back/bootstrap.php';

if (!function_exists('boot_superadmin_summary_view_model')) {
    function boot_superadmin_summary_view_model(?BootStatusService $service = null): array
    {
        $service = $service ?: new BootStatusService();
        $summary = $service->summary();

        return [
            'available' => (bool)($summary['available'] ?? false),
            'health' => is_array($summary['health'] ?? null) ? $summary['health'] : [],
            'latest' => is_array($summary['latest'] ?? null) ? $summary['latest'] : null,
            'history' => is_array($summary['history'] ?? null) ? $summary['history'] : [],
        ];
    }
}

if (!function_exists('boot_superadmin_latest_view_model')) {
    function boot_superadmin_latest_view_model(array $summary): ?array
    {
        $latest = $summary['latest'] ?? null;
        return is_array($latest) ? $latest : null;
    }
}

if (!function_exists('boot_superadmin_history_view_model')) {
    function boot_superadmin_history_view_model(array $summary): array
    {
        $history = $summary['history'] ?? [];
        return is_array($history) ? $history : [];
    }
}
