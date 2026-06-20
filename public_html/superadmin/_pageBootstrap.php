<?php

declare(strict_types=1);
require_once __DIR__ . '/../../back/bootstrap.php';
require_once __DIR__ . '/support/helpers.php';
$bootService = new BootStatusService();
$bootSummary = $bootService->summary();
$bootLatest = $bootSummary['latest'] ?? null;
$bootHealth = $bootSummary['health'] ?? $bootService->health();
$bootHistory = $bootSummary['history'] ?? [];
$bootPaths = ['reports_dir' => boot_reports_dir(), 'latest_report' => boot_effective_latest_report_path(), 'sample_reports_dir' => boot_sample_reports_dir()];
