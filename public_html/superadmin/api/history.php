<?php
require_once __DIR__ . '/../support/api.php';
boot_superadmin_json(['module' => 'boot', 'items' => (new BootHistoryService())->recent(10)]);
