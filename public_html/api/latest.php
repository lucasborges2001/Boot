<?php

declare(strict_types=1);
require_once __DIR__ . '/../../back/bootstrap.php';
header('Content-Type: application/json; charset=utf-8');
$latest = (new BootStatusService())->latest();
http_response_code($latest === null ? 404 : 200);
echo json_encode($latest ?: ['ok' => false, 'error' => 'No Boot snapshot available'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
