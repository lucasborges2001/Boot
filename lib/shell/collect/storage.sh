#!/usr/bin/env bash
# Allowlisted filesystem capacity/inode telemetry and optional disk I/O counters.

if [[ -n "${BOOT_COLLECT_STORAGE_SH_INCLUDED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
BOOT_COLLECT_STORAGE_SH_INCLUDED=1

boot_collect_filesystems_json() {
  command -v python3 >/dev/null 2>&1 || { printf '[]\n'; return; }

  BOOT_STORAGE_ALLOWLIST="${BOOT_FILESYSTEM_ALLOWLIST:-/}" \
  BOOT_STORAGE_EXCLUDELIST="${BOOT_FILESYSTEM_EXCLUDELIST:-/proc,/sys,/dev,/run}" \
  BOOT_STORAGE_PROC_ROOT="${BOOT_PROC_ROOT:-/proc}" python3 - <<'PY'
import json
import os

allowlist = [item.strip() for item in os.environ.get('BOOT_STORAGE_ALLOWLIST', '/').split(',') if item.strip()]
exclude = [item.rstrip('/') or '/' for item in os.environ.get('BOOT_STORAGE_EXCLUDELIST', '').split(',') if item.strip()]
proc_root = os.environ.get('BOOT_STORAGE_PROC_ROOT', '/proc')
pseudo = {'proc', 'sysfs', 'devtmpfs', 'devpts', 'tmpfs', 'cgroup', 'cgroup2', 'securityfs', 'debugfs', 'tracefs', 'pstore', 'configfs', 'fusectl', 'mqueue', 'hugetlbfs', 'rpc_pipefs', 'autofs'}
mounts = []

try:
    with open(os.path.join(proc_root, 'self', 'mountinfo'), 'r', encoding='utf-8') as handle:
        for line in handle:
            left, right = line.rstrip('\n').split(' - ', 1)
            left_fields = left.split()
            right_fields = right.split()
            if len(left_fields) < 5 or len(right_fields) < 2:
                continue
            mountpoint = left_fields[4].replace('\\040', ' ').replace('\\011', '\t').replace('\\134', '\\')
            mounts.append((mountpoint, right_fields[0], right_fields[1]))
except (OSError, ValueError):
    mounts = []

def mount_meta(path):
    candidates = [item for item in mounts if path == item[0] or path.startswith(item[0].rstrip('/') + '/')]
    if not candidates:
        return (None, None)
    mountpoint, fstype, source = max(candidates, key=lambda item: len(item[0]))
    return (fstype, source)

def excluded(path):
    for prefix in exclude:
        if path == prefix or path.startswith(prefix.rstrip('/') + '/'):
            return True
    return False

def percent(used, total):
    return round(used * 100.0 / total, 1) if total > 0 else None

items = []
seen = set()
for configured in allowlist:
    if not configured.startswith('/'):
        continue
    visible_path = os.path.normpath(configured)
    if excluded(visible_path) or visible_path in seen:
        continue
    seen.add(visible_path)
    try:
        resolved = os.path.realpath(visible_path)
        stats = os.statvfs(resolved)
    except OSError:
        items.append({'mount': visible_path, 'available': False, 'reason': 'unreadable'})
        continue

    fstype, source = mount_meta(resolved)
    if fstype in pseudo:
        continue
    total = stats.f_blocks * stats.f_frsize
    available = stats.f_bavail * stats.f_frsize
    used = max(0, total - stats.f_bfree * stats.f_frsize)
    inode_total = stats.f_files
    inode_available = stats.f_favail
    inode_used = max(0, inode_total - stats.f_ffree)
    items.append({
        'mount': visible_path,
        'available': True,
        'filesystem_type': fstype,
        'device': os.path.basename(source) if source and source.startswith('/dev/') else None,
        'total_bytes': total,
        'used_bytes': used,
        'available_bytes': available,
        'used_percent': percent(used, total),
        'inodes_total': inode_total,
        'inodes_used': inode_used,
        'inodes_available': inode_available,
        'inodes_used_percent': percent(inode_used, inode_total),
    })

print(json.dumps(items, ensure_ascii=False, separators=(',', ':')))
PY
}

boot_collect_disk_io_json() {
  command -v python3 >/dev/null 2>&1 || { printf '{"available":false,"source":"unavailable"}\n'; return; }

  BOOT_DISK_IO_ALLOWLIST_VALUE="${BOOT_DISK_DEVICE_ALLOWLIST:-}" \
  BOOT_DISK_IO_PROC_ROOT="${BOOT_PROC_ROOT:-/proc}" python3 - <<'PY'
import json
import os

allowlist = {item.strip() for item in os.environ.get('BOOT_DISK_IO_ALLOWLIST_VALUE', '').split(',') if item.strip()}
path = os.path.join(os.environ.get('BOOT_DISK_IO_PROC_ROOT', '/proc'), 'diskstats')
result = {
    'available': False,
    'source': 'procfs',
    'devices': sorted(allowlist),
    'read_operations': None,
    'write_operations': None,
    'read_bytes': None,
    'write_bytes': None,
    'io_time_ms': None,
}
if not allowlist:
    result['source'] = 'disabled_without_allowlist'
    print(json.dumps(result, separators=(',', ':')))
    raise SystemExit

totals = {'read_operations': 0, 'write_operations': 0, 'read_bytes': 0, 'write_bytes': 0, 'io_time_ms': 0}
matched = set()
try:
    with open(path, 'r', encoding='utf-8') as handle:
        for line in handle:
            fields = line.split()
            if len(fields) < 14 or fields[2] not in allowlist:
                continue
            name = fields[2]
            matched.add(name)
            try:
                totals['read_operations'] += int(fields[3])
                totals['read_bytes'] += int(fields[5]) * 512
                totals['write_operations'] += int(fields[7])
                totals['write_bytes'] += int(fields[9]) * 512
                totals['io_time_ms'] += int(fields[12])
            except ValueError:
                continue
except OSError:
    matched = set()

if matched:
    result.update(totals)
    result['available'] = True
    result['devices'] = sorted(matched)
print(json.dumps(result, ensure_ascii=False, separators=(',', ':')))
PY
}
