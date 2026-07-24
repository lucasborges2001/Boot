# Testing y validación

## Smoke integrado

Requiere `Base` disponible como repositorio hermano o mediante `BASE_DIR`:

```bash
cd submodules/Boot
BASE_DIR=../Base bash scripts/dev/smoke.sh
```

El smoke valida:

- sintaxis PHP;
- sintaxis Bash;
- compilación sintáctica Python sin generar `__pycache__`;
- tests shell;
- tests PHP con verificaciones explícitas;
- CLI disposable mediante `bin/boot-report-test`.

Los tests PHP no usan `assert()`: una condición incumplida lanza error y termina con código distinto de cero aunque `zend.assertions` esté deshabilitado.

## Tests focalizados

```bash
BASE_DIR=../Base bash test/shell/boot_cpu_memory_test.sh
BASE_DIR=../Base bash test/shell/boot_network_rates_test.sh
BASE_DIR=../Base bash test/shell/boot_system_collect_test.sh
BASE_DIR=../Base bash test/shell/boot_history_retention_test.sh
BASE_DIR=../Base bash test/shell/boot_collect_test.sh

php test/php/BootReportNormalizerTest.php
php test/php/BootReportReaderTest.php
php test/php/BootStatusServiceTest.php
php test/php/BootTelemetryV2Test.php
php test/php/BootTrendServiceTest.php
php test/php/BootApiContractTest.php
```

Cobertura declarada:

- CPU mediante dos muestras deterministas;
- memoria, swap y PSI;
- updates sin coincidencias de seguridad bajo `set -o pipefail`;
- timeouts de comandos externos;
- tasas de red con muestra previa;
- rechazo de picos ante counter reset y reboot;
- persistencia append-only;
- pruning confinado, sin seguir symlinks;
- compatibilidad de lectura v1/v2;
- ausencia de fallback implícito a fixtures;
- sanitización de rutas en API y SuperAdmin;
- tendencias con promedio, delta y dirección;
- endpoints read-only públicos y SuperAdmin.

## CI parcial

```txt
.github/workflows/boot-static-ci.yml
```

El workflow ejecuta en cada push/PR:

- lint PHP/Bash/Python;
- colectores aislados que no dependen de Base;
- auditoría de la frontera web read-only;
- generación de paquetes server/web.

No ejecuta la suite PHP ni el smoke completo porque `Base` es privado y el `GITHUB_TOKEN` de `Boot` no tiene acceso cross-repository. No debe agregarse un token persistente al código. Para CI integrado se requiere un secreto de solo lectura o un reusable workflow autorizado explícitamente.

## CLI sin Telegram

```bash
BOOT_REPORTS_DIR="$(mktemp -d)/reports" \
BOOT_SEND_TELEGRAM=false \
BOOT_FILESYSTEM_ALLOWLIST=/ \
BOOT_NETWORK_INTERFACE_ALLOWLIST= \
BOOT_DISK_DEVICE_ALLOWLIST= \
bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null
```

Ejecutar dos veces para comprobar tasas sobre una interfaz real:

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

`lib/shell/collect.sh` quedó como orquestador breve; el constructor v2 vive en `lib/python/build_report.py`. El objetivo es:

```txt
0 error(s), 0 warning(s), 0 info
```

Ese resultado requiere comprobación en el checkout integrado.

## Seguridad web

```bash
grep -RInE 'shell_exec|exec\(|system\(|passthru|proc_open|popen' public_html back || true
grep -RIn '\$throwable->getMessage()' public_html || true
```

## Producción

No ejecutar automáticamente:

```bash
scripts/server/test-production.sh
```

Puede tocar systemd y Telegram real. Debe ejecutarse solo en un servidor controlado.
