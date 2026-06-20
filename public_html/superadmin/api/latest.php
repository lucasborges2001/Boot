<?php
require_once __DIR__ . '/../support/api.php';
$payload = (new BootStatusService())->latest();
boot_superadmin_json($payload ?: ['ok' => false, 'error' => 'No Boot snapshot available'], $payload ? 200 : 404);
