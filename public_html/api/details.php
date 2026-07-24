<?php

declare(strict_types=1);

/**
 * @file public_html/api/details.php
 * @brief Expone detalle read-only de CPU, memoria, filesystems, red o I/O de disco.
 */

require_once __DIR__ . '/_common.php';

boot_api_require_get();

try {
    $section = boot_api_section_from_query();
    $allowed = ['cpu', 'memory', 'filesystems', 'network', 'disk_io'];
    if (!in_array($section, $allowed, true)) {
        boot_api_send_error('INVALID_SECTION', 'Use cpu, memory, filesystems, network or disk_io', 400);
        return;
    }

    $details = (new BootStatusService())->details($section);
    if ($details === null) {
        boot_api_send_error('NO_SNAPSHOT', 'No Boot snapshot available', 404);
        return;
    }

    boot_api_send_ok(['details' => $details]);
} catch (Throwable $throwable) {
    boot_api_internal_error();
}
