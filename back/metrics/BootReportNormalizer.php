<?php

declare(strict_types=1);

/**
 * @file back/metrics/BootReportNormalizer.php
 * @brief Normaliza report.json de Boot al contrato de métricas Base y al contrato API Boot.
 */

final class BootReportNormalizer implements MetricSnapshotNormalizer
{
    public function normalize(array $raw): MetricSnapshot
    {
        $generatedAt = $this->parseDate((string)($raw['generated_at'] ?? 'now'));
        $statusRaw = is_array($raw['status'] ?? null) ? $raw['status'] : [];

        $status = new MetricStatus(
            (string)($statusRaw['overall'] ?? 'unknown'),
            (string)($statusRaw['severity'] ?? MetricSeverity::UNKNOWN),
            (string)($statusRaw['summary'] ?? 'Sin estado disponible'),
            $generatedAt,
            BOOT_MODULE_NAME
        );

        return new MetricSnapshot(
            BOOT_MODULE_NAME,
            (string)($raw['schema_version'] ?? BOOT_SCHEMA_VERSION),
            $generatedAt,
            $status,
            is_array($raw['metrics'] ?? null) ? $raw['metrics'] : [],
            [
                'server' => is_array($raw['server'] ?? null) ? $raw['server'] : [],
                'cpu' => is_array($raw['cpu'] ?? null) ? $raw['cpu'] : [],
                'memory' => is_array($raw['memory'] ?? null) ? $raw['memory'] : [],
                'filesystems' => is_array($raw['filesystems'] ?? null) ? $raw['filesystems'] : [],
                'disk_io' => is_array($raw['disk_io'] ?? null) ? $raw['disk_io'] : [],
                'network_interfaces' => is_array($raw['network_interfaces'] ?? null) ? $raw['network_interfaces'] : [],
                'updates' => is_array($raw['updates'] ?? null) ? $raw['updates'] : [],
                'services' => is_array($raw['services'] ?? null) ? $raw['services'] : [],
                'collection' => is_array($raw['collection'] ?? null) ? $raw['collection'] : [],
                'telegram' => is_array($raw['telegram'] ?? null) ? $raw['telegram'] : [],
            ],
            is_array($raw['artifacts'] ?? null) ? $raw['artifacts'] : [],
            $raw
        );
    }

    public function normalizeForApi(array $raw): array
    {
        $safeRaw = $this->sanitizeRawForApi($raw);
        $snapshot = $this->normalize($safeRaw);
        $status = $snapshot->status()->toArray();
        $schemaVersion = (int)($safeRaw['schema_version'] ?? BOOT_SCHEMA_VERSION);

        return [
            'module' => BOOT_MODULE_NAME,
            'schema_version' => $schemaVersion,
            'generated_at' => (string)($safeRaw['generated_at'] ?? $snapshot->generatedAt()->format(DateTimeInterface::ATOM)),
            'server' => is_array($safeRaw['server'] ?? null) ? $safeRaw['server'] : [],
            'status' => [
                'overall' => (string)($safeRaw['status']['overall'] ?? $status['status'] ?? 'unknown'),
                'severity' => (string)($safeRaw['status']['severity'] ?? $status['severity'] ?? 'unknown'),
                'summary' => (string)($safeRaw['status']['summary'] ?? $status['summary'] ?? ''),
            ],
            'metrics' => $snapshot->metrics(),
            'cpu' => is_array($safeRaw['cpu'] ?? null) ? $safeRaw['cpu'] : [],
            'memory' => is_array($safeRaw['memory'] ?? null) ? $safeRaw['memory'] : [],
            'filesystems' => is_array($safeRaw['filesystems'] ?? null) ? $safeRaw['filesystems'] : [],
            'disk_io' => is_array($safeRaw['disk_io'] ?? null) ? $safeRaw['disk_io'] : [],
            'network_interfaces' => is_array($safeRaw['network_interfaces'] ?? null) ? $safeRaw['network_interfaces'] : [],
            'updates' => is_array($safeRaw['updates'] ?? null) ? $safeRaw['updates'] : [],
            'services' => is_array($safeRaw['services'] ?? null) ? $safeRaw['services'] : [],
            'collection' => is_array($safeRaw['collection'] ?? null) ? $safeRaw['collection'] : [],
            'units' => is_array($safeRaw['units'] ?? null) ? $safeRaw['units'] : [],
            'telegram' => is_array($safeRaw['telegram'] ?? null) ? $safeRaw['telegram'] : [],
            'artifacts' => $snapshot->artifacts(),
            'compatibility' => [
                'supported' => in_array($schemaVersion, BOOT_SUPPORTED_SCHEMA_VERSIONS, true),
                'supported_schema_versions' => BOOT_SUPPORTED_SCHEMA_VERSIONS,
                'legacy_v1' => $schemaVersion === 1,
            ],
            'base_snapshot' => $snapshot->toArray(),
        ];
    }

    private function sanitizeRawForApi(array $raw): array
    {
        $safe = $raw;
        $server = is_array($safe['server'] ?? null) ? $safe['server'] : [];
        $server['ip_wan'] = null;
        $safe['server'] = $server;

        $safe['artifacts'] = [
            'report_json' => 'latest/report.json',
            'summary_txt' => 'latest/summary.txt',
        ];

        $safe['filesystems'] = array_values(array_filter(
            is_array($safe['filesystems'] ?? null) ? $safe['filesystems'] : [],
            static fn($item): bool => is_array($item) && isset($item['mount']) && is_string($item['mount']) && str_starts_with($item['mount'], '/')
        ));

        $safe['network_interfaces'] = array_values(array_filter(
            is_array($safe['network_interfaces'] ?? null) ? $safe['network_interfaces'] : [],
            static fn($item): bool => is_array($item)
                && isset($item['name'])
                && is_string($item['name'])
                && preg_match('/^[A-Za-z0-9_.:-]+$/', $item['name']) === 1
        ));

        return $safe;
    }

    private function parseDate(string $value): DateTimeImmutable
    {
        try {
            return new DateTimeImmutable($value !== '' ? $value : 'now');
        } catch (Exception $exception) {
            return new DateTimeImmutable('now', new DateTimeZone('UTC'));
        }
    }
}
