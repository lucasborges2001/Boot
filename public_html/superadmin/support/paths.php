<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/support/paths.php
 * @brief Normaliza rutas read-only de reportes Boot para mostrarlas en SuperAdmin.
 */

require_once __DIR__ . '/../../../back/bootstrap.php';

if (!function_exists('boot_superadmin_paths_view_model')) {
    function boot_superadmin_paths_view_model(): array
    {
        $latestReport = boot_effective_latest_report_path();
        $reportsDir = boot_reports_dir();
        $sampleReportsDir = boot_sample_reports_dir();

        return [
            'latest_report' => $latestReport,
            'latest_report_exists' => is_file($latestReport),
            'reports_dir' => $reportsDir,
            'reports_dir_exists' => is_dir($reportsDir),
            'sample_reports_dir' => $sampleReportsDir,
            'sample_reports_dir_exists' => is_dir($sampleReportsDir),
        ];
    }
}

if (!function_exists('boot_superadmin_contract_paths')) {
    function boot_superadmin_contract_paths(array $pathsViewModel): array
    {
        return [
            'report_json' => (string)($pathsViewModel['latest_report'] ?? ''),
            'summary_txt' => rtrim(dirname((string)($pathsViewModel['latest_report'] ?? '')), '/') . '/summary.txt',
            'reports_dir' => (string)($pathsViewModel['reports_dir'] ?? ''),
        ];
    }
}
