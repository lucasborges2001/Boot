#!/usr/bin/env bash
# Exercise the server archive in a disposable source tree, never on production.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP"/{bin,lib,config,scripts/server,systemd}
cp "$ROOT/scripts/server/package-server.sh" "$TMP/scripts/server/package-server.sh"
printf '#!/usr/bin/env bash\n' > "$TMP/bin/boot-report"
chmod +x "$TMP/bin/boot-report"
printf 'SECRET\n' > "$TMP/config/server.env"
printf 'SECRET\n' > "$TMP/config/.env"
mkdir -p "$TMP/lib/__pycache__"
printf 'bytecode\n' > "$TMP/lib/__pycache__/collector.pyc"
touch "$TMP/README-INSTALL.md" "$TMP/README.md" "$TMP/boot-report.sh"
for folder in lib config systemd; do touch "$TMP/$folder/.test-fixture"; done
bash "$TMP/scripts/server/package-server.sh" >/dev/null
PACKAGE="$TMP/dist/boot-server.tar.gz"
[[ -f "$PACKAGE" ]]
CONTENTS="$(tar -tzf "$PACKAGE")"
grep -Fxq bin/boot-report <<<"$CONTENTS" || { echo 'FAIL: missing Boot entrypoint' >&2; exit 1; }
for forbidden in config/server.env config/.env lib/__pycache__/collector.pyc; do
  if grep -Fxq "$forbidden" <<<"$CONTENTS"; then
    echo "FAIL: Boot server package leaks $forbidden" >&2
    exit 1
  fi
done
echo BOOT_SERVER_PACKAGE_CONTRACT_PASS
