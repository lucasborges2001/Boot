<?php

declare(strict_types=1);
function boot_superadmin_e($value): string { return htmlspecialchars((string)$value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8'); }
function boot_superadmin_percent($value): string { return is_numeric($value) ? number_format((float)$value, 1) . '%' : 'n/a'; }
