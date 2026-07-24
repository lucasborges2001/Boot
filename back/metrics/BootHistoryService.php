<?php

declare(strict_types=1);

/**
 * @file back/metrics/BootHistoryService.php
 * @brief Lista snapshots históricos Boot sin exponer rutas internas y omitiendo archivos inválidos.
 */

final class BootHistoryService
{
    private $reportsDir;
    private $normalizer;

    public function __construct(?string $reportsDir = null, ?BootReportNormalizer $normalizer = null)
    {
        $this->reportsDir = $reportsDir ?: boot_reports_dir();
        $this->normalizer = $normalizer ?: new BootReportNormalizer();
    }

    public function recent(int $limit = 10): array
    {
        $limit = max(1, min(100, $limit));
        $items = [];
        $dirs = boot_history_dirs(['reports_dir' => $this->reportsDir]);

        foreach ($dirs as $dir) {
            if (count($items) >= $limit) {
                break;
            }

            $repository = new JsonMetricSnapshotRepository($dir . '/report.json');
            $raw = $repository->read();
            if ($raw === null || ($raw['module'] ?? null) !== BOOT_MODULE_NAME) {
                continue;
            }

            $normalized = $this->normalizer->normalizeForApi($raw);
            $normalized['snapshot_id'] = basename($dir);
            $items[] = $normalized;
        }

        if ($items === [] && is_dir(boot_sample_reports_dir())) {
            $sample = new JsonMetricSnapshotRepository(boot_sample_latest_report_path());
            $raw = $sample->read();
            if ($raw !== null && ($raw['module'] ?? null) === BOOT_MODULE_NAME) {
                $normalized = $this->normalizer->normalizeForApi($raw);
                $normalized['snapshot_id'] = 'sample';
                $items[] = $normalized;
            }
        }

        return $items;
    }
}
