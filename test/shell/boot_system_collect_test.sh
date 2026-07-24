#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/lib/shell/collect/system.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

cat > "$tmp/bin/apt-get" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat > "$tmp/bin/apt" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == "list" && "${2:-}" == "--upgradable" ]]; then
  printf 'Listing...\nexample/stable 2.0 amd64 [upgradable from: 1.0]\n'
fi
SH
chmod +x "$tmp/bin/apt-get" "$tmp/bin/apt"

PATH="$tmp/bin:$PATH"
export PATH BOOT_COMMAND_TIMEOUT_SECONDS=2
read -r total security <<<"$(boot_collect_updates)"
test "$total" = "1"
test "$security" = "0"
test "$(boot_command_timeout_seconds)" = "2"

BOOT_COMMAND_TIMEOUT_SECONDS=invalid
test "$(boot_command_timeout_seconds)" = "5"

echo "boot_system_collect_test OK"
