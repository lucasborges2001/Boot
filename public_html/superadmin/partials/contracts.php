<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/partials/contracts.php
 * @brief Renderiza contratos y paths read-only del panel Boot SuperAdmin.
 */
?>
<section class="card">
  <h2>Contratos y paths</h2>
  <ul>
    <li>Report JSON: <code><?php echo boot_superadmin_e($bootContractPaths['report_json'] ?? $bootPaths['latest_report'] ?? ''); ?></code></li>
    <li>Summary TXT: <code><?php echo boot_superadmin_e($bootContractPaths['summary_txt'] ?? ''); ?></code></li>
    <li>Reports dir: <code><?php echo boot_superadmin_e($bootPaths['reports_dir'] ?? ''); ?></code></li>
    <li>Sample dir: <code><?php echo boot_superadmin_e($bootPaths['sample_reports_dir'] ?? ''); ?></code></li>
    <li>Schema: <code>boot/v1</code></li>
  </ul>
</section>
