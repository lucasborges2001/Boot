<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/partials/telemetry-details.php
 * @brief Renderiza detalle read-only de filesystems e interfaces de red allowlisted.
 */

$bootFilesystems = is_array($bootLatest['filesystems'] ?? null) ? $bootLatest['filesystems'] : [];
$bootInterfaces = is_array($bootLatest['network_interfaces'] ?? null) ? $bootLatest['network_interfaces'] : [];
$bootFormatBytes = static function ($value): string {
    if (!is_numeric($value)) {
        return 'n/a';
    }
    $bytes = (float)$value;
    $units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
    $index = 0;
    while ($bytes >= 1024 && $index < count($units) - 1) {
        $bytes /= 1024;
        $index++;
    }
    return number_format($bytes, $index === 0 ? 0 : 1, '.', '') . ' ' . $units[$index];
};
?>
<section class="card">
  <h2>Filesystems allowlisted</h2>
  <?php if ($bootFilesystems === []): ?>
    <p>Sin filesystems detallados disponibles.</p>
  <?php else: ?>
    <table>
      <thead><tr><th>Mount</th><th>Tipo</th><th>Uso</th><th>Disponible</th><th>Inodos</th></tr></thead>
      <tbody>
      <?php foreach ($bootFilesystems as $filesystem): ?>
        <tr>
          <td><code><?php echo boot_superadmin_e($filesystem['mount'] ?? ''); ?></code></td>
          <td><?php echo boot_superadmin_e($filesystem['filesystem_type'] ?? 'n/a'); ?></td>
          <td><?php echo boot_superadmin_e(boot_superadmin_percent($filesystem['used_percent'] ?? null)); ?></td>
          <td><?php echo boot_superadmin_e($bootFormatBytes($filesystem['available_bytes'] ?? null)); ?></td>
          <td><?php echo boot_superadmin_e(boot_superadmin_percent($filesystem['inodes_used_percent'] ?? null)); ?></td>
        </tr>
      <?php endforeach; ?>
      </tbody>
    </table>
  <?php endif; ?>
</section>

<section class="card">
  <h2>Red allowlisted</h2>
  <?php if ($bootInterfaces === []): ?>
    <p>Sin interfaces configuradas. Definir <code>BOOT_NETWORK_INTERFACE_ALLOWLIST</code> para habilitar contadores.</p>
  <?php else: ?>
    <table>
      <thead><tr><th>Interfaz</th><th>Estado</th><th>Velocidad</th><th>RX acumulado</th><th>TX acumulado</th><th>Tasa RX/TX</th></tr></thead>
      <tbody>
      <?php foreach ($bootInterfaces as $interface): ?>
        <?php $rates = is_array($interface['rates'] ?? null) ? $interface['rates'] : []; $counters = is_array($interface['counters'] ?? null) ? $interface['counters'] : []; ?>
        <tr>
          <td><code><?php echo boot_superadmin_e($interface['name'] ?? ''); ?></code></td>
          <td><?php echo boot_superadmin_e(($interface['operstate'] ?? 'n/a') . ' · ' . ($interface['rate_status'] ?? 'n/a')); ?></td>
          <td><?php echo isset($interface['speed_mbps']) ? boot_superadmin_e($interface['speed_mbps'] . ' Mbps') : 'n/a'; ?></td>
          <td><?php echo boot_superadmin_e($bootFormatBytes($counters['rx_bytes'] ?? null)); ?></td>
          <td><?php echo boot_superadmin_e($bootFormatBytes($counters['tx_bytes'] ?? null)); ?></td>
          <td><?php echo boot_superadmin_e($bootFormatBytes($rates['rx_bytes_per_second'] ?? null) . '/s · ' . $bootFormatBytes($rates['tx_bytes_per_second'] ?? null) . '/s'); ?></td>
        </tr>
      <?php endforeach; ?>
      </tbody>
    </table>
  <?php endif; ?>
</section>
