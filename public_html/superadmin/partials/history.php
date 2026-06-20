<section class="card"><h2>Historial reciente</h2><table><thead><tr><th>Fecha</th><th>Host</th><th>Severidad</th><th>Resumen</th></tr></thead><tbody>
<?php foreach ($bootHistory as $item): ?><tr><td><?php echo boot_superadmin_e($item['generated_at'] ?? ''); ?></td><td><?php echo boot_superadmin_e($item['server']['hostname'] ?? ''); ?></td><td><?php echo boot_superadmin_e($item['status']['severity'] ?? ''); ?></td><td><?php echo boot_superadmin_e($item['status']['summary'] ?? ''); ?></td></tr><?php endforeach; ?>
</tbody></table></section>
