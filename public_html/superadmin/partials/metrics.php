<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/partials/metrics.php
 * @brief Renderiza métricas principales de recursos, updates y servicios fallidos de Boot.
 */

$m = $bootLatest['metrics'] ?? [];
$u = $bootLatest['updates'] ?? [];
$s = $bootLatest['services'] ?? [];
?>
<section class="card"><h2>Métricas</h2><div class="metrics">
  <div><span>Load 1m</span><strong><?php echo boot_superadmin_e($m['cpu_load_1m'] ?? 'n/a'); ?></strong></div>
  <div><span>Load 5m</span><strong><?php echo boot_superadmin_e($m['cpu_load_5m'] ?? 'n/a'); ?></strong></div>
  <div><span>RAM</span><strong><?php echo boot_superadmin_e(boot_superadmin_percent($m['ram_used_percent'] ?? null)); ?></strong></div>
  <div><span>Disco /</span><strong><?php echo boot_superadmin_e(boot_superadmin_percent($m['disk_root_used_percent'] ?? null)); ?></strong></div>
  <div><span>Updates</span><strong><?php echo boot_superadmin_e($u['total'] ?? 0); ?></strong></div>
  <div><span>Security</span><strong><?php echo boot_superadmin_e($u['security'] ?? 0); ?></strong></div>
  <div><span>Reboot</span><strong><?php echo !empty($u['reboot_required']) ? 'sí' : 'no'; ?></strong></div>
  <div><span>Servicios fallidos</span><strong><?php echo boot_superadmin_e($s['failed_count'] ?? 0); ?></strong></div>
</div></section>
