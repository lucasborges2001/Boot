<?php

declare(strict_types=1);

/**
 * @file back/metrics/BootStatusService.php
 * @brief Servicio de lectura read-only para health, latest, detalles, tendencias y resumen SuperAdmin.
 */

final class BootStatusService
{
    private $reader;
    private $history;
    private $trends;

    public function __construct(
        ?BootReportReader $reader = null,
        ?BootHistoryService $history = null,
        ?BootTrendService $trends = null
    ) {
        $this->reader = $reader ?: new BootReportReader();
        $this->history = $history ?: new BootHistoryService();
        $this->trends = $trends ?: new BootTrendService($this->reader, $this->history);
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
                'summary' => 'No hay snapshot Boot disponible',
                'snapshot_available' => false,
            ];
        }

        $severity = (string)($latest['status']['severity'] ?? 'unknown');
        return [
            'ok' => in_array($severity, ['ok', 'info'], true),
            'module' => BOOT_MODULE_NAME,
            'severity' => $severity,
            'summary' => (string)($latest['status']['summary'] ?? ''),
            'generated_at' => (string)($latest['generated_at'] ?? ''),
            'schema_version' => (int)($latest['schema_version'] ?? BOOT_SCHEMA_VERSION),
            'snapshot_available' => true,
        ];
    }

    public function trends(int $limit = 30): array
    {
        return $this->trends->summary($limit);
    }

    public function operationalSummary(): array
    {
        $latest = $this->latest();
        if ($latest === null) {
            return [
                'available' => false,
                'health' => $this->health(),
                'trends' => $this->trends(),
            ];
        }

        $metrics = is_array($latest['metrics'] ?? null) ? $latest['metrics'] : [];
        $server = is_array($latest['server'] ?? null) ? $latest['server'] : [];
        $updates = is_array($latest['updates'] ?? null) ? $latest['updates'] : [];
        $services = is_array($latest['services'] ?? null) ? $latest['services'] : [];

        return [
            'available' => true,
            'generated_at' => (string)($latest['generated_at'] ?? ''),
            'health' => $this->health(),
            'server' => [
                'hostname' => (string)($server['hostname'] ?? ''),
                'uptime_seconds' => $server['uptime_seconds'] ?? null,
                'cpu_logical' => $server['cpu_logical'] ?? null,
            ],
            'metrics' => [
                'cpu_used_percent' => $metrics['cpu_used_percent'] ?? null,
                'cpu_load_1m' => $metrics['cpu_load_1m'] ?? null,
                'ram_used_percent' => $metrics['ram_used_percent'] ?? null,
                'swap_used_percent' => $metrics['swap_used_percent'] ?? null,
                'disk_root_used_percent' => $metrics['disk_root_used_percent'] ?? null,
            ],
            'updates' => [
                'total' => $updates['total'] ?? null,
                'security' => $updates['security'] ?? null,
                'reboot_required' => $updates['reboot_required'] ?? null,
            ],
            'failed_services' => $services['failed_count'] ?? null,
            'trends' => $this->trends(),
        ];
    }

    public function details(string $section): ?array
    {
        $latest = $this->latest();
        if ($latest === null) {
            return null;
        }

        $sections = [
            'cpu' => is_array($latest['cpu'] ?? null) ? $latest['cpu'] : [],
            'memory' => is_array($latest['memory'] ?? null) ? $latest['memory'] : [],
            'filesystems' => is_array($latest['filesystems'] ?? null) ? $latest['filesystems'] : [],
            'network' => is_array($latest['network_interfaces'] ?? null) ? $latest['network_interfaces'] : [],
            'disk_io' => is_array($latest['disk_io'] ?? null) ? $latest['disk_io'] : [],
        ];

        return array_key_exists($section, $sections) ? [
            'section' => $section,
            'generated_at' => (string)($latest['generated_at'] ?? ''),
            'data' => $sections[$section],
        ] : null;
    }

    public function summary(): array
    {
        $latest = $this->latest();
        if ($latest === null) {
            return [
                'available' => false,
                'health' => $this->health(),
                'trends' => $this->trends(),
                'history' => [],
            ];
        }

        return [
            'available' => true,
            'health' => $this->health(),
            'operational' => $this->operationalSummary(),
            'trends' => $this->trends(),
            'latest' => $latest,
            'history' => $this->history->recent(5),
        ];
    }
}
