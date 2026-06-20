<?php

declare(strict_types=1);

final class BootReportReader implements MetricSnapshotReader
{
    private $path;
    private $normalizer;
    private $lastError;

    public function __construct(?string $path = null, ?BootReportNormalizer $normalizer = null)
    {
        $this->path = $path ?: boot_effective_latest_report_path();
        $this->normalizer = $normalizer ?: new BootReportNormalizer();
        $this->lastError = null;
    }

    public function path(): string
    {
        return $this->path;
    }

    public function rawLatest(): ?array
    {
        $repository = new JsonMetricSnapshotRepository($this->path);
        $data = $repository->read();
        $this->lastError = $repository->lastError();

        return $data;
    }

    public function latest(): ?MetricSnapshot
    {
        $raw = $this->rawLatest();
        if ($raw === null) {
            return null;
        }

        return $this->normalizer->normalize($raw);
    }

    public function latestForApi(): ?array
    {
        $raw = $this->rawLatest();
        if ($raw === null) {
            return null;
        }

        return $this->normalizer->normalizeForApi($raw);
    }

    public function lastError(): ?string
    {
        return $this->lastError;
    }
}
