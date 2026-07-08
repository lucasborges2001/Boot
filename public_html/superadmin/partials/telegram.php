<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/partials/telegram.php
 * @brief Muestra el estado reportado de Telegram sin exponer secretos ni ejecutar envíos.
 */

$t = $bootLatest['telegram'] ?? [];
?>
<section class="card"><h2>Telegram</h2><p>Enabled: <strong><?php echo !empty($t['enabled']) ? 'true' : 'false'; ?></strong></p><p>Last send OK: <strong><?php echo array_key_exists('last_send_ok', $t) ? boot_superadmin_e(var_export($t['last_send_ok'], true)) : 'n/a'; ?></strong></p><p>Message ID: <?php echo boot_superadmin_e($t['message_id'] ?? 'n/a'); ?></p></section>
