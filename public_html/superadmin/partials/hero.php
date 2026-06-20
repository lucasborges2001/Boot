<section class="hero card">
  <div>
    <p class="eyebrow">Observabilidad del servidor</p>
    <h1>Boot</h1>
    <p>Snapshot read-only generado por <code>bin/boot-report</code>. La UI no ejecuta comandos del sistema.</p>
  </div>
  <span class="badge badge-<?php echo boot_superadmin_e($bootHealth['severity'] ?? 'unknown'); ?>"><?php echo boot_superadmin_e($bootHealth['severity'] ?? 'unknown'); ?></span>
</section>
