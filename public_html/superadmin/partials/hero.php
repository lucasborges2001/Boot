<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/partials/hero.php
 * @brief Encabezado de estado para la pantalla SuperAdmin de Boot.
 */
?>
<section class="hero card">
  <div>
    <p class="eyebrow">Observabilidad del servidor</p>
    <h1>Boot</h1>
    <p>Snapshot read-only generado por <code>bin/boot-report</code>. La UI no ejecuta comandos del sistema.</p>
  </div>
  <span class="badge badge-<?php echo boot_superadmin_e($bootHealth['severity'] ?? 'unknown'); ?>"><?php echo boot_superadmin_e($bootHealth['severity'] ?? 'unknown'); ?></span>
</section>
