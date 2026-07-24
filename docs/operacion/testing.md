# Testing y validación

## Smoke principal

```bash
cd submodules/Boot
BASE_DIR=../Base bash scripts/dev/smoke.sh
```

El smoke ejecuta sintaxis PHP, tests shell, tests PHP y el CLI disposable.

## Sintaxis

```bash
find . -name '*.php' -print0 | xargs -0 -n1 php -l
find . \( -name '*.sh' -o -path './scripts/test.sh' \) -print0 | xargs -0 -n1 bash -n
```

## Tests focalizados v2

```bash
BASE_DIR=../Base bash test/shell/boot_cpu_memory_test.sh
BASE_DIR=../Base bash test/shell/boot_network_rates_test.sh
BASE_DIR=../Base bash test/shell/boot_history_retention_test.sh
BASE_DIR=../Base bash test/shell/boot_collect_test.sh

php test/php/BootReportNormalizerTest.php
php test/php/BootTelemetryV2Test.php
php test/php/BootApiContractTest.php
```

Cobertura declarada:

- CPU mediante dos muestras deterministas;
- memoria, swap y PSI;
- tasas de red con muestra previa;
- rechazo de picos ante counter reset y reboot;
- persistencia append-only;
- pruning confinado, sin seguir symlinks;
- compatibilidad de lectura v1/v2;
- sanitización de rutas en API;
- endpoints read-only públicos y SuperAdmin.

## CLI sin Telegram

```bash
BOOT_REPORTS_DIR="$(mktemp -d)/reports" \
BOOT_SEND_TELEGRAM=false \
BOOT_FILESYSTEM_ALLOWLIST=/ \
BOOT_NETWORK_INTERFACE_ALLOWLIST= \
BOOT_DISK_DEVICE_ALLOWLIST= \
bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null
```

Ejecutar dos veces para comprobar que las tasas de red solo aparecen en la segunda muestra cuando se configuró una interfaz real:

```bash
reports="$(mktemp -d)/reports"
BOOT_REPORTS_DIR="$reports" BOOT_SEND_TELEGRAM=false BOOT_NETWORK_INTERFACE_ALLOWLIST=eth0 bin/boot-report --no-telegram
sleep 2
BOOT_REPORTS_DIR="$reports" BOOT_SEND_TELEGRAM=false BOOT_NETWORK_INTERFACE_ALLOWLIST=eth0 bin/boot-report --no-telegram --print \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["network_interfaces"])'
```

## Packaging

```bash
bash bin/boot-report-package
tar -tzf dist/boot-server.tar.gz | head
tar -tzf dist/boot-web.tar.gz | head
```

## Auditor estructural

Desde `Pruebas`:

```bash
bash scripts/quality/audit_structure.sh ./submodules/Boot/
```

Objetivo posterior al split de `lib/shell/collect.sh`:

```txt
0 error(s), 0 warning(s), 0 info
```

Este resultado debe verificarse en un checkout integrado; no se deduce solo por el tamaño de archivos.

## Seguridad web

```bash
grep -RInE 'shell_exec|exec\(|system\(|passthru|proc_open|popen' public_html back || true
grep -RIn '\$throwable->getMessage()' public_html || true
```

`exec(` puede aparecer en tests CLI. No debe aparecer dentro de `public_html` ni `back`.

## Tests productivos

No ejecutar automáticamente:

```bash
scripts/server/test-production.sh
```

Ese script puede tocar systemd y Telegram real. Debe ejecutarse solo en servidor controlado.
