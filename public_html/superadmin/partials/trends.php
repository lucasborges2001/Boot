<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/partials/trends.php
 * @brief Renderiza tendencias básicas calculadas por Boot sobre su historial local.
 */

$trendMetrics = is_array($bootTrends['metrics'] ?? null) ? $bootTrends['metrics'] : [];
$trendLabels = [
    'cpu_used_percent' => ['CPU usada', '%'],
    'cpu_load_1m' => ['Load 1m', ''],
    'ram_used_percent' => ['RAM', '%'],
    'swap_used_percent' => ['Swap', '%'],
    'disk_root_used_percent' => ['Disco /', '%'],
    'network_rx_bytes_per_second' => ['Red RX', ' B/s'],
    'network_tx_bytes_per_second' => ['Red TX', ' B/s'],
];
?>
<section class="card">
  <h2>Tendencias</h2>
  <p>Ventana: <?php echo boot_superadmin_e($bootTrends['from'] ?? 'n/a'); ?> → <?php echo boot_superadmin_e($bootTrends['to'] ?? 'n/a'); ?> · snapshots: <?php echo boot_superadmin_e($bootTrends['sample_count'] ?? 0); ?></p>
  <?php if ($trendMetrics === []): ?>
    <p>Sin suficientes métricas históricas válidas.</p>
  <?php else: ?>
    <div class="metrics">
      <?php foreach ($trendLabels as $key => [$label, $unit]): ?>
        <?php if (!isset($trendMetrics[$key]) || !is_array($trendMetrics[$key])) { continue; } $trend = $trendMetrics[$key]; ?>
        <div>
          <span><?php echo boot_superadmin_e($label); ?></span>
          <strong><?php echo boot_superadmin_e(($trend['latest'] ?? 'n/a') . $unit); ?></strong>
          <small>prom. <?php echo boot_superadmin_e(($trend['average'] ?? 'n/a') . $unit); ?> · Δ <?php echo boot_superadmin_e(($trend['delta'] ?? 'n/a') . $unit); ?> · <?php echo boot_superadmin_e($trend['direction'] ?? 'n/a'); ?></small>
        </div>
      <?php endforeach; ?>
    </div>
  <?php endif; ?>
</section>
