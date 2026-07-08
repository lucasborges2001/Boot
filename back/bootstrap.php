<?php

declare(strict_types=1);

/**
 * @file back/bootstrap.php
 * @brief Bootstrap PHP del módulo Boot y carga compatible de Base.
 */

require_once __DIR__ . '/support/base-resolver.php';

boot_bootstrap_load_base();
boot_bootstrap_load_boot();

if (!function_exists('boot_bootstrap')) {
    function boot_bootstrap(): void
    {
        // Requiring this file is enough to load Boot classes.
    }
}
