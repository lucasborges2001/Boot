<?php

declare(strict_types=1);

if (!function_exists('boot_env_bool')) {
    function boot_env_bool(string $name, bool $default): bool
    {
        $value = getenv($name);
        if ($value === false || $value === '') {
            return $default;
        }

        $value = strtolower(trim((string)$value));
        if (in_array($value, ['1', 'true', 'yes', 'y', 'on', 'enabled'], true)) {
            return true;
        }
        if (in_array($value, ['0', 'false', 'no', 'n', 'off', 'disabled'], true)) {
            return false;
        }

        return $default;
    }
}

if (!function_exists('boot_config_load')) {
    function boot_config_load(array $override = []): array
    {
        $config = [
            'enabled' => boot_env_bool('BOOT_ENABLED', true),
            'reports_dir' => getenv('BOOT_REPORTS_DIR') ?: BOOT_DEFAULT_REPORTS_DIR,
            'retention_days' => (int)(getenv('BOOT_RETENTION_DAYS') ?: BOOT_DEFAULT_RETENTION_DAYS),
            'send_telegram' => boot_env_bool('BOOT_SEND_TELEGRAM', true),
            'base_dir' => boot_resolve_base_dir(),
        ];

        foreach ($override as $key => $value) {
            $config[$key] = $value;
        }

        return $config;
    }
}
