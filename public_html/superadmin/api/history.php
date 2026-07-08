<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/api/history.php
 * @brief Expone historial Boot read-only para SuperAdmin con contrato JSON visible.
 */

require_once __DIR__ . '/_common.php';

$bootApiMethod = $_SERVER['REQUEST_METHOD'] ?? 'GET';
boot_api_require_method('GET', $bootApiMethod);

try {
    $bootApiResponse = [
        'ok' => true,
        'module' => 'boot',
        'code' => 'OK',
        'data' => [
            'items' => (new BootHistoryService())->recent(10),
        ],
    ];

    http_response_code(200);
    if (PHP_SAPI !== 'cli' && !headers_sent()) {
        header('Content-Type: application/json; charset=utf-8');
    }
    echo json_encode($bootApiResponse, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
    return;
} catch (Throwable $throwable) {
    $bootApiResponse = [
        'ok' => false,
        'module' => 'boot',
        'code' => 'INTERNAL_ERROR',
        'error' => [
            'message' => $throwable->getMessage(),
        ],
    ];

    http_response_code(500);
    if (PHP_SAPI !== 'cli' && !headers_sent()) {
        header('Content-Type: application/json; charset=utf-8');
    }
    echo json_encode($bootApiResponse, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
    return;
}
