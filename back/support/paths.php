<?php

declare(strict_types=1);

if (!function_exists('boot_path_join')) {
    function boot_path_join(string ...$parts): string
    {
        $result = '';
        foreach ($parts as $index => $part) {
            $part = (string)$part;
            if ($part === '') {
                continue;
            }
            if ($index === 0) {
                $result = rtrim($part, '/');
                continue;
            }
            $result .= '/' . trim($part, '/');
        }
        return $result === '' ? '/' : $result;
    }
}

if (!function_exists('boot_reports_dir')) {
    function boot_reports_dir(?array $config = null): string
    {
        if (is_array($config) && isset($config['reports_dir']) && is_string($config['reports_dir']) && $config['reports_dir'] !== '') {
            return rtrim($config['reports_dir'], '/');
        }

        $env = getenv('BOOT_REPORTS_DIR');
        if (is_string($env) && $env !== '') {
            return rtrim($env, '/');
        }

        return BOOT_DEFAULT_REPORTS_DIR;
    }
}

if (!function_exists('boot_sample_reports_dir')) {
    function boot_sample_reports_dir(): string
    {
        return boot_module_root() . '/var/sample-reports';
    }
}

if (!function_exists('boot_latest_report_path')) {
    function boot_latest_report_path(?array $config = null): string
    {
        return boot_reports_dir($config) . '/latest/report.json';
    }
}

if (!function_exists('boot_latest_summary_path')) {
    function boot_latest_summary_path(?array $config = null): string
    {
        return boot_reports_dir($config) . '/latest/summary.txt';
    }
}

if (!function_exists('boot_sample_latest_report_path')) {
    function boot_sample_latest_report_path(): string
    {
        return boot_sample_reports_dir() . '/latest/report.json';
    }
}

if (!function_exists('boot_effective_latest_report_path')) {
    function boot_effective_latest_report_path(?array $config = null): string
    {
        $configured = boot_latest_report_path($config);
        if (is_file($configured)) {
            return $configured;
        }

        $sample = boot_sample_latest_report_path();
        if (is_file($sample)) {
            return $sample;
        }

        return $configured;
    }
}

if (!function_exists('boot_history_dirs')) {
    function boot_history_dirs(?array $config = null): array
    {
        $reportsDir = boot_reports_dir($config);
        if (!is_dir($reportsDir)) {
            $reportsDir = boot_sample_reports_dir();
        }

        $dirs = glob($reportsDir . '/*', GLOB_ONLYDIR) ?: [];
        $dirs = array_values(array_filter($dirs, static function (string $dir): bool {
            return basename($dir) !== 'latest' && is_file($dir . '/report.json');
        }));
        rsort($dirs, SORT_STRING);

        return $dirs;
    }
}
