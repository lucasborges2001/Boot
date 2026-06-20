<?php

declare(strict_types=1);
require_once __DIR__ . '/../../back/bootstrap.php';
putenv('BOOT_REPORTS_DIR=' . __DIR__ . '/../../var/sample-reports');
$service = new BootStatusService();
$health = $service->health();
assert($health['module'] === 'boot');
assert(isset($health['severity']));
echo "BootStatusServiceTest OK\n";
