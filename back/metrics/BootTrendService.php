<?php

declare(strict_types=1);

/**
 * @file back/metrics/BootTrendService.php
 * @brief Calcula tendencias básicas read-only sobre snapshots Boot normalizados.
 */

final class BootTrendService
{
    private BootReportReader $reader;
    private BootHistoryService $history;

    public function __construct(?BootReportReader $reader = null, ?BootHistoryService $history = null)
    {
        $this->reader = $reader ?: new BootReportReader();
        $this->history = $history ?: new BootHistoryService();
    }

    public function summary(int $limit = 30): array
    {
        $limit = max(2, min(100, $limit));
        $snapshots = $this->history->recent($limit);
        $latest = $this->reader->latestForApi();
        if ($latest !== null) {
            $snapshots[] = $latest;
        }

        $byTimestamp = [];
        foreach ($snapshots as $snapshot) {
            if (!is_array($snapshot)) {
                continue;
            }
            $generatedAt = trim((string)($snapshot['generated_at'] ?? ''));
            if ($generatedAt === '') {
                continue;
            }
            $byTimestamp[$generatedAt] = $snapshot;
        }
        ksort($byTimestamp, SORT_STRING);
        $snapshots = array_values($byTimestamp);

        if ($snapshots === []) {
            return [
                'available' => false,
                'sample_count' => 0,
                'from' => null,
                'to' => null,
                'metrics' => [],
            ];
        }

        $metricKeys = [
            'cpu_used_percent',
            'cpu_load_1m',
            'ram_used_percent',
            'swap_used_percent',
            'disk_root_used_percent',
            'network_rx_bytes_per_second',
            'network_tx_bytes_per_second',
        ];
        $metrics = [];
        foreach ($metricKeys as $metricKey) {
            $values = [];
            foreach ($snapshots as $snapshot) {
                $value = $this->metricValue($snapshot, $metricKey);
                if ($value !== null) {
                    $values[] = $value;
                }
            }
            if ($values !== []) {
                $metrics[$metricKey] = $this->summarizeValues($values);
            }
        }

        return [
            'available' => count($snapshots) >= 2,
            'sample_count' => count($snapshots),
            'from' => (string)($snapshots[0]['generated_at'] ?? ''),
            'to' => (string)($snapshots[count($snapshots) - 1]['generated_at'] ?? ''),
            'metrics' => $metrics,
        ];
    }

    private function metricValue(array $snapshot, string $metricKey): ?float
    {
        if (str_starts_with($metricKey, 'network_')) {
            $rateKey = $metricKey === 'network_rx_bytes_per_second'
                ? 'rx_bytes_per_second'
                : 'tx_bytes_per_second';
            $total = 0.0;
            $found = false;
            $interfaces = is_array($snapshot['network_interfaces'] ?? null)
                ? $snapshot['network_interfaces']
                : [];
            foreach ($interfaces as $interface) {
                $rates = is_array($interface['rates'] ?? null) ? $interface['rates'] : [];
                if (isset($rates[$rateKey]) && is_numeric($rates[$rateKey])) {
                    $total += (float)$rates[$rateKey];
                    $found = true;
                }
            }
            return $found ? $total : null;
        }

        $metrics = is_array($snapshot['metrics'] ?? null) ? $snapshot['metrics'] : [];
        return isset($metrics[$metricKey]) && is_numeric($metrics[$metricKey])
            ? (float)$metrics[$metricKey]
            : null;
    }

    private function summarizeValues(array $values): array
    {
        $first = (float)$values[0];
        $latest = (float)$values[count($values) - 1];
        $delta = $latest - $first;
        $direction = abs($delta) < 0.01 ? 'stable' : ($delta > 0 ? 'rising' : 'falling');

        return [
            'samples' => count($values),
            'first' => round($first, 2),
            'latest' => round($latest, 2),
            'minimum' => round(min($values), 2),
            'maximum' => round(max($values), 2),
            'average' => round(array_sum($values) / count($values), 2),
            'delta' => round($delta, 2),
            'direction' => $direction,
        ];
    }
}
