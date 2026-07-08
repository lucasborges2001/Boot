<?php

declare(strict_types=1);

/**
 * @file public_html/api/history.php
 * @brief Lista snapshots históricos Boot de forma read-only con límite acotado.
 */

require_once __DIR__ . '/_common.php';

$bootApiMethod = $_SERVER['REQUEST_METHOD'] ?? 'GET';
boot_api_require_method('GET', $bootApiMethod);

try {
    $limit = boot_api_limit_from_query(10, 1, 50);
    $bootApiResponse = [
        'ok' => true,
        'module' => 'boot',
        'code' => 'OK',
        'data' => [
            'items' => (new BootHistoryService())->recent($limit),
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
