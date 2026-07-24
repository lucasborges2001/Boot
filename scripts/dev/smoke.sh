#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

find "$DIR" -name '*.php' -print0 | xargs -0 -n1 php -l >/dev/null
find "$DIR" -name '*.sh' -print0 | xargs -0 -n1 bash -n

while IFS= read -r -d '' python_file; do
  python3 -c 'import pathlib,sys; path=pathlib.Path(sys.argv[1]); compile(path.read_text(encoding="utf-8"), str(path), "exec")' "$python_file"
done < <(find "$DIR" -name '*.py' -print0)

for test_file in "$DIR"/test/shell/*.sh; do
  bash "$test_file"
done
for test_file in "$DIR"/test/php/[A-Z]*Test.php; do
  php "$test_file"
done

"$DIR/bin/boot-report-test" >/dev/null
echo "Boot smoke OK"
