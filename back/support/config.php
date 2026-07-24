<?php

declare(strict_types=1);

/**
 * @file back/support/config.php
 * @brief Configuración segura de Boot desde variables de entorno y overrides explícitos.
 */

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

if (!function_exists('boot_env_int')) {
    function boot_env_int(string $name, int $default, int $minimum = 0, ?int $maximum = null): int
    {
        $value = getenv($name);
        $parsed = ($value !== false && preg_match('/^-?\d+$/', (string)$value) === 1) ? (int)$value : $default;
        $parsed = max($minimum, $parsed);
        return $maximum === null ? $parsed : min($maximum, $parsed);
    }
}

if (!function_exists('boot_env_csv')) {
    function boot_env_csv(string $name, array $default = []): array
    {
        $value = getenv($name);
        if ($value === false || trim((string)$value) === '') {
            return $default;
        }

        $items = array_map('trim', explode(',', (string)$value));
        return array_values(array_unique(array_filter($items, static fn(string $item): bool => $item !== '')));
    }
}

if (!function_exists('boot_config_load')) {
    function boot_config_load(array $override = []): array
    {
        $legacyEnabled = boot_env_bool('BOOT_ENABLED', true);
        $config = [
            'enabled' => boot_env_bool('BOOT_TELEMETRY_ENABLED', $legacyEnabled),
            'reports_dir' => getenv('BOOT_REPORTS_DIR') ?: BOOT_DEFAULT_REPORTS_DIR,
            'retention_days' => boot_env_int(
                'BOOT_HISTORY_RETENTION_DAYS',
                boot_env_int('BOOT_RETENTION_DAYS', BOOT_DEFAULT_RETENTION_DAYS, 0),
                0
            ),
            'history_max_files' => boot_env_int('BOOT_HISTORY_MAX_FILES', BOOT_DEFAULT_HISTORY_MAX_FILES, 0),
            'filesystem_allowlist' => boot_env_csv('BOOT_FILESYSTEM_ALLOWLIST', ['/']),
            'filesystem_excludelist' => boot_env_csv('BOOT_FILESYSTEM_EXCLUDELIST', ['/proc', '/sys', '/dev', '/run']),
            'network_interface_allowlist' => boot_env_csv('BOOT_NETWORK_INTERFACE_ALLOWLIST'),
            'disk_device_allowlist' => boot_env_csv('BOOT_DISK_DEVICE_ALLOWLIST'),
            'include_lan_ip' => boot_env_bool('BOOT_INCLUDE_LAN_IP', true),
            'send_telegram' => boot_env_bool('BOOT_SEND_TELEGRAM', true),
            'base_dir' => boot_resolve_base_dir(),
        ];

        foreach ($override as $key => $value) {
            $config[$key] = $value;
        }

        return $config;
    }
}
