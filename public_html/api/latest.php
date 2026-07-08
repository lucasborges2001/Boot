<?php

declare(strict_types=1);

/**
 * @file public_html/api/latest.php
 * @brief Devuelve el último snapshot Boot normalizado o un error JSON estable si falta.
 */

require_once __DIR__ . '/_common.php';

$bootApiMethod = $_SERVER['REQUEST_METHOD'] ?? 'GET';
boot_api_require_method('GET', $bootApiMethod);

try {
    $latest = (new BootStatusService())->latest();
    if ($latest === null) {
        $bootApiResponse = [
            'ok' => false,
            'module' => 'boot',
            'code' => 'NO_SNAPSHOT',
            'error' => [
                'message' => 'No Boot snapshot available',
            ],
        ];

        http_response_code(404);
        if (PHP_SAPI !== 'cli' && !headers_sent()) {
            header('Content-Type: application/json; charset=utf-8');
        }
        echo json_encode($bootApiResponse, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
        return;
    }

    $bootApiResponse = [
        'ok' => true,
        'module' => 'boot',
        'code' => 'OK',
        'data' => [
            'latest' => $latest,
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
