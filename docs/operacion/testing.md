# Testing y validación

## Smoke principal seguro

```bash
cd submodules/Boot
bash scripts/dev/smoke.sh
```

Este smoke ejecuta:

1. `php -l` sobre archivos PHP.
2. Tests shell en `test/shell/*.sh`.
3. Tests PHP en `test/php/*.php`.
4. `bin/boot-report-test`.

Debe poder correr sin Telegram real y sin escribir fuera de directorios temporales.

## Test CLI disposable

```bash
bin/boot-report-test
```

Crea un directorio temporal, deshabilita Telegram, genera JSON y verifica:

- JSON válido;
- `latest/report.json` existente;
- `latest/summary.txt` existente.

## Validación manual sin Telegram

```bash
BOOT_REPORTS_DIR="$(mktemp -d)/reports" \
BOOT_SEND_TELEGRAM=false \
bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null
```

## Validación PHP/API local

```bash
find . -name '*.php' -print0 | xargs -0 -n1 php -l
php test/php/BootReportNormalizerTest.php
php test/php/BootReportReaderTest.php
php test/php/BootStatusServiceTest.php
php test/php/BootApiContractTest.php
```

## Validación shell

```bash
bash test/shell/base_resolution_test.sh
bash test/shell/boot_collect_test.sh
bash test/shell/boot_persist_test.sh
bash test/shell/boot_render_test.sh
bash test/shell/runtime_entrypoints_test.sh
bash test/shell/boot_packaging_test.sh
```

## Packaging

```bash
bash bin/boot-report-package
tar -tzf dist/boot-server.tar.gz >/tmp/boot-server.files
tar -tzf dist/boot-web.tar.gz >/tmp/boot-web.files
grep -q '^bin/boot-report$' /tmp/boot-server.files
grep -q '^public_html/api/health.php$' /tmp/boot-web.files
```

## Test productivo manual

`scripts/server/test-production.sh` queda reservado para servidor instalado y usuario root. Puede consultar Telegram real, systemd y journalctl.

No forma parte de smokes automáticos ni de CI local defensivo.

Ejemplo controlado:

```bash
scripts/server/test-production.sh --no-telegram-test
```

## Validación host opcional

Desde `Pruebas`:

```bash
php submodules/Base/bin/base-host-submodules-contract \
  --root . \
  --gitmodules .gitmodules \
  --manifest config/submodules.php \
  --mode check

bash scripts/preflight_readonly.sh || true
bash scripts/quality/audit_structure.sh ./submodules/Boot/
```

`Boot` es opcional y no bloqueante, por lo que una suite host futura debería declararse como tooling/observabilidad, no como runtime-app.

## Gaps que quedan

| Gap | Riesgo | Test sugerido |
|---|---|---|
| `lib/shell/collect.sh` sigue siendo grande | Deuda de mantenibilidad P1/P2. | Refactor compatible por dominios con fixture de JSON. |
| API con servidor HTTP real no está cubierta acá | Diferencias de headers/status entre CLI y web server. | `php -S 127.0.0.1:0` + `curl`. |
| Telegram real no probado por smoke | Falla operativa por permisos/token/chat. | Corrida manual productiva con bot de prueba. |
