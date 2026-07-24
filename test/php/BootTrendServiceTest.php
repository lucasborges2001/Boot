<?php

declare(strict_types=1);

require_once __DIR__ . '/_bootstrap.php';

boot_test_run('BootTrendServiceTest', static function (): void {
    $root = sys_get_temp_dir() . '/boot-trends-' . bin2hex(random_bytes(6));
    $timestamps = [
        '2026-07-24T15:00:00Z' => [20.0, 40.0, 70.0, 100.0, 50.0],
        '2026-07-24T15:01:00Z' => [30.0, 50.0, 72.0, 200.0, 100.0],
        '2026-07-24T15:02:00Z' => [25.0, 60.0, 71.0, 300.0, 150.0],
    ];

    try {
        foreach ($timestamps as $generatedAt => [$cpu, $ram, $disk, $rx, $tx]) {
            $directory = str_replace(['-', ':'], '', $generatedAt);
            $snapshotDir = $root . '/' . $directory;
            mkdir($snapshotDir, 0777, true);
            $report = [
                'module' => 'boot',
                'schema_version' => 2,
                'generated_at' => $generatedAt,
                'server' => ['hostname' => 'trend-host', 'uptime_seconds' => 100],
                'status' => ['overall' => 'ok', 'severity' => 'ok', 'summary' => 'ok'],
                'metrics' => [
                    'cpu_used_percent' => $cpu,
                    'cpu_load_1m' => $cpu / 10,
                    'ram_used_percent' => $ram,
                    'swap_used_percent' => 0.0,
                    'disk_root_used_percent' => $disk,
                ],
                'network_interfaces' => [[
                    'name' => 'eth0',
                    'rates' => [
                        'rx_bytes_per_second' => $rx,
                        'tx_bytes_per_second' => $tx,
                    ],
                ]],
            ];
            file_put_contents(
                $snapshotDir . '/report.json',
                json_encode($report, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE)
            );
        }

        mkdir($root . '/latest', 0777, true);
        copy($root . '/20260724T150200Z/report.json', $root . '/latest/report.json');

        $reader = new BootReportReader($root . '/latest/report.json');
        $history = new BootHistoryService($root);
        $trends = (new BootTrendService($reader, $history))->summary(10);

        boot_test_same(true, $trends['available'] ?? null, 'Trend window must be available');
        boot_test_same(3, $trends['sample_count'] ?? null, 'Unexpected deduplicated sample count');
        boot_test_same(50.0, $trends['metrics']['ram_used_percent']['average'] ?? null, 'RAM average changed');
        boot_test_same(20.0, $trends['metrics']['ram_used_percent']['delta'] ?? null, 'RAM delta changed');
        boot_test_same('rising', $trends['metrics']['ram_used_percent']['direction'] ?? null, 'RAM direction changed');
        boot_test_same(71.0, $trends['metrics']['disk_root_used_percent']['latest'] ?? null, 'Disk latest changed');
        boot_test_same(300.0, $trends['metrics']['network_rx_bytes_per_second']['latest'] ?? null, 'RX latest changed');
        boot_test_same(150.0, $trends['metrics']['network_tx_bytes_per_second']['latest'] ?? null, 'TX latest changed');
    } finally {
        if (is_dir($root)) {
            $iterator = new RecursiveIteratorIterator(
                new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS),
                RecursiveIteratorIterator::CHILD_FIRST
            );
            foreach ($iterator as $item) {
                $item->isDir() ? rmdir($item->getPathname()) : unlink($item->getPathname());
            }
            rmdir($root);
        }
    }
});
