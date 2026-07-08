#!/usr/bin/env bash
set -euo pipefail

cat <<'TXT'
Boot tiene dos rutas de validación:

  Desarrollo seguro:
    bash scripts/dev/smoke.sh

  Operación manual productiva:
    ejecutar scripts/server/test-production.sh como usuario root en el servidor instalado.

Este wrapper no ejecuta Telegram real, systemd ni comandos de operación productiva.
TXT
