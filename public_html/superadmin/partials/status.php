<section class="grid two">
  <article class="card"><h2>Estado general</h2><p class="big"><?php echo boot_superadmin_e($bootHealth['summary'] ?? 'Sin estado'); ?></p><p>Última ejecución: <?php echo boot_superadmin_e($bootHealth['generated_at'] ?? 'n/a'); ?></p></article>
  <article class="card"><h2>Servidor</h2><p>Hostname: <strong><?php echo boot_superadmin_e($bootLatest['server']['hostname'] ?? 'n/a'); ?></strong></p><p>Kernel: <?php echo boot_superadmin_e($bootLatest['server']['kernel'] ?? 'n/a'); ?></p><p>LAN: <?php echo boot_superadmin_e($bootLatest['server']['ip_lan'] ?? 'n/a'); ?></p></article>
</section>
