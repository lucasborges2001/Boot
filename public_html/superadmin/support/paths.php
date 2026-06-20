<?php

declare(strict_types=1);
require_once __DIR__ . '/../../../back/bootstrap.php';
return ['latest_report' => boot_effective_latest_report_path(), 'reports_dir' => boot_reports_dir(), 'sample_reports_dir' => boot_sample_reports_dir()];
