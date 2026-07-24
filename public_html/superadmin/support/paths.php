<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/support/paths.php
 * @brief Normaliza disponibilidad y paths lógicos de reportes Boot para SuperAdmin.
 */

require_once __DIR__ . '/../../../back/bootstrap.php';

if (!function_exists('boot_superadmin_paths_view_model')) {
    function boot_superadmin_paths_view_model(): array
    {
        $latestReport = boot_effective_latest_report_path();
        $reportsDir = boot_reports_dir();

        return [
            'latest_report' => 'latest/report.json',
            'latest_summary' => 'latest/summary.txt',
            'latest_report_exists' => is_file($latestReport),
            'reports_dir_configured' => $reportsDir !== '',
            'reports_dir_exists' => is_dir($reportsDir),
            'sample_reports_enabled' => boot_sample_reports_enabled(),
            'sample_fixture_exists' => is_file(boot_sample_latest_report_path()),
        ];
    }
}

if (!function_exists('boot_superadmin_contract_paths')) {
    function boot_superadmin_contract_paths(array $pathsViewModel): array
    {
        return [
            'report_json' => (string)($pathsViewModel['latest_report'] ?? 'latest/report.json'),
            'summary_txt' => (string)($pathsViewModel['latest_summary'] ?? 'latest/summary.txt'),
        ];
    }
}
