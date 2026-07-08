<?php

declare(strict_types=1);

/**
 * @file public_html/superadmin/index.php
 * @brief Vista SuperAdmin read-only de observabilidad Boot.
 */

require __DIR__ . '/_pageBootstrap.php';
?>
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Boot · Observabilidad</title>
  <link rel="stylesheet" href="boot-superadmin.css">
</head>
<body>
  <main class="boot-shell">
    <?php require __DIR__ . '/partials/hero.php'; ?>
    <?php require __DIR__ . '/partials/status.php'; ?>
    <?php require __DIR__ . '/partials/metrics.php'; ?>
    <?php require __DIR__ . '/partials/telegram.php'; ?>
    <?php require __DIR__ . '/partials/history.php'; ?>
    <?php require __DIR__ . '/partials/contracts.php'; ?>
  </main>
  <script src="assets/boot-superadmin.js"></script>
</body>
</html>
