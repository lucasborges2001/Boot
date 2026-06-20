<?php

declare(strict_types=1);

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
                'updates' => is_array($raw['updates'] ?? null) ? $raw['updates'] : [],
                'services' => is_array($raw['services'] ?? null) ? $raw['services'] : [],
                'telegram' => is_array($raw['telegram'] ?? null) ? $raw['telegram'] : [],
            ],
            is_array($raw['artifacts'] ?? null) ? $raw['artifacts'] : [],
            $raw
        );
    }

    public function normalizeForApi(array $raw): array
    {
        $snapshot = $this->normalize($raw);
        $status = $snapshot->status()->toArray();

        return [
            'module' => BOOT_MODULE_NAME,
            'schema_version' => (int)($raw['schema_version'] ?? BOOT_SCHEMA_VERSION),
            'generated_at' => (string)($raw['generated_at'] ?? $snapshot->generatedAt()->format(DateTimeInterface::ATOM)),
            'server' => is_array($raw['server'] ?? null) ? $raw['server'] : [],
            'status' => [
                'overall' => (string)($raw['status']['overall'] ?? $status['status'] ?? 'unknown'),
                'severity' => (string)($raw['status']['severity'] ?? $status['severity'] ?? 'unknown'),
                'summary' => (string)($raw['status']['summary'] ?? $status['summary'] ?? ''),
            ],
            'metrics' => $snapshot->metrics(),
            'updates' => is_array($raw['updates'] ?? null) ? $raw['updates'] : [],
            'services' => is_array($raw['services'] ?? null) ? $raw['services'] : [],
            'telegram' => is_array($raw['telegram'] ?? null) ? $raw['telegram'] : [],
            'artifacts' => $snapshot->artifacts(),
            'base_snapshot' => $snapshot->toArray(),
        ];
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
