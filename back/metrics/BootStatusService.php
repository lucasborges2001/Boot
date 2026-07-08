<?php

declare(strict_types=1);

/**
 * @file back/metrics/BootStatusService.php
 * @brief Servicio de lectura read-only para health, latest y resumen SuperAdmin de Boot.
 */

final class BootStatusService
{
    private $reader;
    private $history;

    public function __construct(?BootReportReader $reader = null, ?BootHistoryService $history = null)
    {
        $this->reader = $reader ?: new BootReportReader();
        $this->history = $history ?: new BootHistoryService();
    }

    public function latest(): ?array
    {
        return $this->reader->latestForApi();
    }

    public function health(): array
    {
        $latest = $this->latest();
        if ($latest === null) {
            return [
                'ok' => false,
                'module' => BOOT_MODULE_NAME,
                'severity' => 'unknown',
                'summary' => $this->reader->lastError() ?: 'No hay snapshot Boot disponible',
                'latest_path' => $this->reader->path(),
            ];
        }

        $severity = (string)($latest['status']['severity'] ?? 'unknown');
        return [
            'ok' => in_array($severity, ['ok', 'info'], true),
            'module' => BOOT_MODULE_NAME,
            'severity' => $severity,
            'summary' => (string)($latest['status']['summary'] ?? ''),
            'generated_at' => (string)($latest['generated_at'] ?? ''),
            'latest_path' => $this->reader->path(),
        ];
    }

    public function summary(): array
    {
        $latest = $this->latest();
        if ($latest === null) {
            return [
                'available' => false,
                'health' => $this->health(),
                'history' => [],
            ];
        }

        return [
            'available' => true,
            'health' => $this->health(),
            'latest' => $latest,
            'history' => $this->history->recent(5),
        ];
    }
}
