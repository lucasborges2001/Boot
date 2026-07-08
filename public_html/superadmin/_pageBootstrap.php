<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/_pageBootstrap.php
 * @brief Construye el view model read-only usado por la pantalla SuperAdmin de Boot.
 */

require_once __DIR__ . '/../../back/bootstrap.php';
require_once __DIR__ . '/support/helpers.php';
require_once __DIR__ . '/support/config.php';
require_once __DIR__ . '/support/paths.php';
require_once __DIR__ . '/support/health.php';
require_once __DIR__ . '/support/metrics.php';

if (!function_exists('boot_superadmin_page_view_model')) {
    function boot_superadmin_page_view_model(): array
    {
        $service = new BootStatusService();
        $summary = boot_superadmin_summary_view_model($service);
        $paths = boot_superadmin_paths_view_model();
        $config = boot_superadmin_config_view_model();

        return [
            'service' => $service,
            'summary' => $summary,
            'latest' => boot_superadmin_latest_view_model($summary),
            'health' => boot_superadmin_health_view_model($service, $summary),
            'history' => boot_superadmin_history_view_model($summary),
            'paths' => $paths,
            'contract_paths' => boot_superadmin_contract_paths($paths),
            'config' => $config,
            'config_labels' => boot_superadmin_config_labels($config),
        ];
    }
}

$bootViewModel = boot_superadmin_page_view_model();
$bootService = $bootViewModel['service'];
$bootSummary = $bootViewModel['summary'];
$bootLatest = $bootViewModel['latest'];
$bootHealth = $bootViewModel['health'];
$bootHistory = $bootViewModel['history'];
$bootPaths = $bootViewModel['paths'];
$bootContractPaths = $bootViewModel['contract_paths'];
$bootConfig = $bootViewModel['config'];
$bootConfigLabels = $bootViewModel['config_labels'];
