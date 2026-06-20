<?php

declare(strict_types=1);
require_once __DIR__ . '/../../../back/bootstrap.php';
function boot_superadmin_json($payload, int $status = 200): void { http_response_code($status); header('Content-Type: application/json; charset=utf-8'); echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT); }
