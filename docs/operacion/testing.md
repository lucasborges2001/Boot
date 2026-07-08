# Testing y validación

## Smoke principal

```bash
cd submodules/Boot
bash scripts/dev/smoke.sh
```

Este smoke ejecuta:

1. `php -l` sobre archivos PHP.
2. Tests shell en `test/shell/*.sh`.
3. Tests PHP en `test/php/*.php`.
4. `bin/boot-report-test`.

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
BOOT_REPORTS_DIR=/tmp/boot-report/reports \
BOOT_SEND_TELEGRAM=false \
bin/boot-report --no-telegram --print | python3 -m json.tool
```

## Validación PHP/API local

```bash
find . -name '*.php' -print0 | xargs -0 -n1 php -l
php test/php/BootReportNormalizerTest.php
php test/php/BootReportReaderTest.php
php test/php/BootStatusServiceTest.php
```

## Validación shell

```bash
bash test/shell/base_resolution_test.sh
bash test/shell/boot_collect_test.sh
bash test/shell/boot_persist_test.sh
bash test/shell/boot_render_test.sh
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
```

`Boot` es opcional y no bloqueante, por lo que una suite host futura debería declararse como tooling/observabilidad, no como runtime-app.

## Gaps de test detectados

| Gap | Riesgo | Test sugerido |
|---|---|---|
| Packaging no cubierto | Tar puede fallar si faltan manifests referenciados. | `bin/boot-report-package` en CI local. |
| API web no cubierta por smoke dedicado | Puede romperse por bootstrap/rutas. | `php -S` + curl a `health/latest/history`. |
| SuperAdmin read-only no garantizado por test | Puede agregarse acción peligrosa sin detectar. | grep negativo de funciones de ejecución y forms. |
| Telegram real no probado en auditoría | Falla operativa por secretos/permisos. | Corrida manual controlada con bot de prueba. |
