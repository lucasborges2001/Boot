<?php
require_once __DIR__ . '/../support/api.php';
boot_superadmin_json((new BootStatusService())->health());
