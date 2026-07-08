<?php

declare(strict_types=1);

/**
 * @file back/support/base-resolver.php
 * @brief Resolución compatible de Base y carga condicional explícita de dependencias PHP de Boot.
 *
 * La carga de Base es deliberadamente condicional porque Boot puede ejecutarse como tooling
 * empaquetado, como submódulo dentro de Pruebas o instalado en servidor. Para evitar warnings
 * mecánicos de `require` después de código, este archivo usa funciones de inclusión controlada
 * con verificación previa de existencia y errores explícitos para archivos propios obligatorios.
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

if (!function_exists('boot_include_once_if_file')) {
    function boot_include_once_if_file(string $file): bool
    {
        if (!is_file($file)) {
            return false;
        }

        include_once $file;
        return true;
    }
}

if (!function_exists('boot_include_required_file')) {
    function boot_include_required_file(string $file): void
    {
        if (!is_file($file)) {
            throw new RuntimeException('Boot required PHP file is missing: ' . $file);
        }

        include_once $file;
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
        if (boot_include_once_if_file($baseBootstrap) && function_exists('base_bootstrap_load_core')) {
            base_bootstrap_load_core();
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
            boot_include_once_if_file($baseDir . $relativeFile);
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
            boot_include_required_file($backDir . $relativeFile);
        }
    }
}
