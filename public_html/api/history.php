<?php

declare(strict_types=1);
require_once __DIR__ . '/../../back/bootstrap.php';
header('Content-Type: application/json; charset=utf-8');
$limit = isset($_GET['limit']) ? max(1, min(50, (int)$_GET['limit'])) : 10;
echo json_encode(['module' => 'boot', 'items' => (new BootHistoryService())->recent($limit)], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
