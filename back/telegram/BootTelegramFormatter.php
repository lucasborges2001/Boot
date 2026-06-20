<?php

declare(strict_types=1);

final class BootTelegramFormatter
{
    public function formatHtml(array $report): string
    {
        $server = is_array($report['server'] ?? null) ? $report['server'] : [];
        $status = is_array($report['status'] ?? null) ? $report['status'] : [];
        $metrics = is_array($report['metrics'] ?? null) ? $report['metrics'] : [];
        $updates = is_array($report['updates'] ?? null) ? $report['updates'] : [];
        $services = is_array($report['services'] ?? null) ? $report['services'] : [];

        $hostname = TelegramHtml::escape((string)($server['hostname'] ?? 'unknown'));
        $severity = TelegramHtml::escape((string)($status['severity'] ?? 'unknown'));
        $summary = TelegramHtml::escape((string)($status['summary'] ?? 'Sin resumen'));
        $generatedAt = TelegramHtml::escape((string)($report['generated_at'] ?? ''));

        return implode("\n", [
            '<b>Boot report</b> · <code>' . $hostname . '</code>',
            'Estado: <b>' . $severity . '</b>',
            $summary,
            'Load: <code>' . TelegramHtml::escape((string)($metrics['cpu_load_1m'] ?? 'n/a')) . '</code> / <code>' . TelegramHtml::escape((string)($metrics['cpu_load_5m'] ?? 'n/a')) . '</code> / <code>' . TelegramHtml::escape((string)($metrics['cpu_load_15m'] ?? 'n/a')) . '</code>',
            'RAM: <code>' . TelegramHtml::escape((string)($metrics['ram_used_percent'] ?? 'n/a')) . '%</code> · Disco: <code>' . TelegramHtml::escape((string)($metrics['disk_root_used_percent'] ?? 'n/a')) . '%</code>',
            'Updates: <code>' . TelegramHtml::escape((string)($updates['total'] ?? 0)) . '</code> · Security: <code>' . TelegramHtml::escape((string)($updates['security'] ?? 0)) . '</code>',
            'Servicios fallidos: <code>' . TelegramHtml::escape((string)($services['failed_count'] ?? 0)) . '</code>',
            'Generado: <code>' . $generatedAt . '</code>',
        ]);
    }
}
