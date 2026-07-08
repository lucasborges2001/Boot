#!/usr/bin/env bash
# Actualizaciones legacy para Boot.

sys_updates_snapshot() {
  local sim holds
  sim="$(apt-get -s upgrade 2>/dev/null || true)"
  holds="$(apt-mark showhold 2>/dev/null || true)"

  python3 -c 'import re,sys
holds=set([x.strip() for x in sys.argv[1].splitlines() if x.strip()])
sec=[]; reg=[]
for line in sys.stdin.read().splitlines():
    if not line.startswith("Inst "):
        continue
    m=re.match(r"^Inst\s+(\S+)(?:\s+\[[^\]]+\])?\s+\(([^ \s]+)\s+([^)]*)\)$", line)
    if not m:
        m=re.match(r"^Inst\s+(\S+)\s+\(([^)]*)\)$", line)
        if not m:
            continue
        pkg=m.group(1); origin=m.group(2)
    else:
        pkg=m.group(1); origin=m.group(3)
    o=origin.lower()
    is_sec=("security" in o) or ("-security" in o)
    (sec if is_sec else reg).append(pkg)

def uniq(xs):
    seen=set(); out=[]
    for x in xs:
        if x not in seen:
            out.append(x); seen.add(x)
    return out

sec=uniq(sec); reg=uniq(reg)
print("--SECURITY--")
print("\n".join(sec))
print("--REGULAR--")
print("\n".join(reg))
print("--HELD--")
print("\n".join(sorted(holds)))' "$holds" <<<"$sim"
}
