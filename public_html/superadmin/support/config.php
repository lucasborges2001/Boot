<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/support/config.php
 * @brief Construye un view model seguro de configuración Boot para SuperAdmin sin exponer secretos.
 */

require_once __DIR__ . '/../../../back/bootstrap.php';

if (!function_exists('boot_superadmin_config_view_model')) {
    function boot_superadmin_config_view_model(array $override = []): array
    {
        $config = boot_config_load($override);

        return [
            'enabled' => (bool)($config['enabled'] ?? false),
            'send_telegram' => (bool)($config['send_telegram'] ?? false),
            'reports_dir' => (string)($config['reports_dir'] ?? ''),
            'retention_days' => (int)($config['retention_days'] ?? 0),
            'base_dir_resolved' => is_string($config['base_dir'] ?? null) && $config['base_dir'] !== '',
        ];
    }
}

if (!function_exists('boot_superadmin_config_labels')) {
    function boot_superadmin_config_labels(array $configViewModel): array
    {
        return [
            'enabled' => !empty($configViewModel['enabled']) ? 'enabled' : 'disabled',
            'telegram' => !empty($configViewModel['send_telegram']) ? 'configured-or-enabled' : 'disabled',
            'base' => !empty($configViewModel['base_dir_resolved']) ? 'resolved' : 'missing',
        ];
    }
}
