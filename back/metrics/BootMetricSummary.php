<?php

declare(strict_types=1);

/**
 * @file back/metrics/BootMetricSummary.php
 * @brief DTO mínimo para resumir snapshots Boot normalizados.
 */

final class BootMetricSummary
{
    private $hostname;
    private $generatedAt;
    private $severity;
    private $summary;
    private $metrics;

    public function __construct(string $hostname, string $generatedAt, string $severity, string $summary, array $metrics = [])
    {
        $this->hostname = $hostname;
        $this->generatedAt = $generatedAt;
        $this->severity = $severity;
        $this->summary = $summary;
        $this->metrics = $metrics;
    }

    public static function fromReport(array $report): self
    {
        $server = is_array($report['server'] ?? null) ? $report['server'] : [];
        $status = is_array($report['status'] ?? null) ? $report['status'] : [];
        $metrics = is_array($report['metrics'] ?? null) ? $report['metrics'] : [];

        return new self(
            (string)($server['hostname'] ?? 'unknown'),
            (string)($report['generated_at'] ?? ''),
            (string)($status['severity'] ?? 'unknown'),
            (string)($status['summary'] ?? 'Sin reporte disponible'),
            $metrics
        );
    }

    public function toArray(): array
    {
        return [
            'hostname' => $this->hostname,
            'generated_at' => $this->generatedAt,
            'severity' => $this->severity,
            'summary' => $this->summary,
            'metrics' => $this->metrics,
        ];
    }
}
