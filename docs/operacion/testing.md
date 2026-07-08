# Testing y validación

## Smoke principal

```bash
cd submodules/Boot
bash scripts/dev/smoke.sh
```

## Sintaxis

```bash
find . -name '*.php' -print0 | xargs -0 -n1 php -l
find . \( -name '*.sh' -o -path './scripts/test.sh' \) -print0 | xargs -0 -n1 bash -n
```

## CLI sin Telegram

```bash
BOOT_REPORTS_DIR="$(mktemp -d)/reports" \
BOOT_SEND_TELEGRAM=false \
bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null
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

Resultado actual esperado:

```txt
0 error(s), 1 warning(s), 0 info
```

Única warning esperada:

```txt
FILE_TOO_LARGE :: lib/shell/collect.sh
```

## Tests productivos

No ejecutar automáticamente:

```bash
scripts/server/test-production.sh
```

Ese script puede tocar systemd y Telegram real. Debe ejecutarse solo en servidor controlado.
