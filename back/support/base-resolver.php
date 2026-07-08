<?php

declare(strict_types=1);

/**
 * @file back/support/base-resolver.php
 * @brief Resolución compatible de Base y carga explícita de clases PHP requeridas por Boot.
 */

if (!function_exists('boot_module_root')) {
    function boot_module_root(): string
    {
        return dirname(__DIR__, 2);
    }
}

if (!function_exists('boot_bootstrap_base_candidates')) {
    function boot_bootstrap_base_candidates(): array
    {
        $root = boot_module_root();
        $candidates = [];

        $env = getenv('BASE_DIR');
        if (is_string($env) && $env !== '') {
            $candidates[] = rtrim($env, '/');
        }

        $candidates[] = dirname($root) . '/Base';
        $candidates[] = dirname(__DIR__, 3) . '/Base';
        $candidates[] = '/opt/base';

        return array_values(array_unique($candidates));
    }
}

if (!function_exists('boot_resolve_base_dir')) {
    function boot_resolve_base_dir(): ?string
    {
        foreach (boot_bootstrap_base_candidates() as $candidate) {
            if (is_dir($candidate . '/back') || is_dir($candidate . '/lib/shell')) {
                return $candidate;
            }
        }

        return null;
    }
}

if (!function_exists('boot_require_once_if_file')) {
    function boot_require_once_if_file(string $file): bool
    {
        if (is_file($file)) {
            require_once $file;
            return true;
        }

        return false;
    }
}

if (!function_exists('boot_bootstrap_load_base')) {
    function boot_bootstrap_load_base(): void
    {
        $baseDir = boot_resolve_base_dir();
        if ($baseDir === null) {
            return;
        }

        $baseBootstrap = $baseDir . '/back/bootstrap.php';
        if (is_file($baseBootstrap)) {
            require_once $baseBootstrap;
            if (function_exists('base_bootstrap_load_core')) {
                base_bootstrap_load_core();
            }
        }

        $baseFiles = [
            '/back/metrics/MetricSeverity.php',
            '/back/metrics/MetricStatus.php',
            '/back/metrics/MetricSnapshot.php',
            '/back/metrics/MetricSnapshotReader.php',
            '/back/metrics/MetricSnapshotNormalizer.php',
            '/back/metrics/JsonMetricSnapshotRepository.php',
            '/back/telegram/TelegramHtml.php',
            '/back/telegram/TelegramResponse.php',
            '/back/telegram/TelegramResponseParser.php',
        ];

        foreach ($baseFiles as $relativeFile) {
            boot_require_once_if_file($baseDir . $relativeFile);
        }
    }
}

if (!function_exists('boot_bootstrap_load_boot')) {
    function boot_bootstrap_load_boot(): void
    {
        $backDir = dirname(__DIR__);
        $bootFiles = [
            '/support/contracts.php',
            '/support/paths.php',
            '/support/config.php',
            '/metrics/BootMetricSummary.php',
            '/metrics/BootReportNormalizer.php',
            '/metrics/BootReportReader.php',
            '/metrics/BootHistoryService.php',
            '/metrics/BootStatusService.php',
            '/telegram/BootTelegramFormatter.php',
        ];

        foreach ($bootFiles as $relativeFile) {
            require_once $backDir . $relativeFile;
        }
    }
}
