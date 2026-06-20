<?php

declare(strict_types=1);
require_once __DIR__ . '/../../../back/bootstrap.php';
return (new BootStatusService())->summary();
