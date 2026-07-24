<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/partials/contracts.php
 * @brief Renderiza contratos lógicos y disponibilidad read-only del panel Boot SuperAdmin.
 */
?>
<section class="card">
  <h2>Contratos</h2>
  <ul>
    <li>Report JSON: <code><?php echo boot_superadmin_e($bootContractPaths['report_json'] ?? 'latest/report.json'); ?></code></li>
    <li>Summary TXT: <code><?php echo boot_superadmin_e($bootContractPaths['summary_txt'] ?? 'latest/summary.txt'); ?></code></li>
    <li>Runtime snapshot: <code><?php echo !empty($bootPaths['latest_report_exists']) ? 'available' : 'missing'; ?></code></li>
    <li>Sample fallback: <code><?php echo !empty($bootPaths['sample_reports_enabled']) ? 'enabled' : 'disabled'; ?></code></li>
    <li>Schema writer: <code>boot/v2</code></li>
    <li>Schema readers: <code>boot/v1, boot/v2</code></li>
  </ul>
</section>
