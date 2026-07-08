<?php

declare(strict_types=1);

/**
 * @file back/metrics/BootHistoryService.php
 * @brief Lista snapshots históricos Boot desde reports_dir o fixtures sample.
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
        $items = [];
        $dirs = boot_history_dirs(['reports_dir' => $this->reportsDir]);

        foreach ($dirs as $dir) {
            if (count($items) >= $limit) {
                break;
            }

            $repository = new JsonMetricSnapshotRepository($dir . '/report.json');
            $raw = $repository->read();
            if ($raw === null) {
                continue;
            }

            $normalized = $this->normalizer->normalizeForApi($raw);
            $normalized['path'] = $dir . '/report.json';
            $items[] = $normalized;
        }

        if ($items === [] && is_dir(boot_sample_reports_dir())) {
            $sample = new JsonMetricSnapshotRepository(boot_sample_latest_report_path());
            $raw = $sample->read();
            if ($raw !== null) {
                $normalized = $this->normalizer->normalizeForApi($raw);
                $normalized['path'] = boot_sample_latest_report_path();
                $items[] = $normalized;
            }
        }

        return $items;
    }
}
