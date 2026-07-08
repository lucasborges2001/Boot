# SuperAdmin y API

## API pública

| Endpoint | Método | Resultado |
|---|---:|---|
| `public_html/api/health.php` | GET | Health del snapshot. |
| `public_html/api/latest.php` | GET | Último reporte. |
| `public_html/api/history.php` | GET | Historial. |

## API SuperAdmin

| Endpoint | Método | Resultado |
|---|---:|---|
| `public_html/superadmin/api/latest.php` | GET | Último reporte para UI. |
| `public_html/superadmin/api/history.php` | GET | Historial para UI. |
| `public_html/superadmin/api/probe.php` | GET | Probe read-only. |

## UI SuperAdmin

Entrada:

```txt
public_html/superadmin/index.php
```

Partials:

```txt
_pageBootstrap.php
partials/hero.php
partials/status.php
partials/metrics.php
partials/telegram.php
partials/history.php
partials/contracts.php
```

## Smoke manual HTTP sugerido

```bash
php -S 127.0.0.1:8099 -t public_html
curl -s http://127.0.0.1:8099/api/health.php | python3 -m json.tool
curl -s http://127.0.0.1:8099/api/latest.php | python3 -m json.tool
curl -s 'http://127.0.0.1:8099/api/history.php?limit=5' | python3 -m json.tool
```

## Hardening read-only sugerido

```bash
grep -RIn "shell_exec\|exec(\|system(\|passthru\|proc_open\|popen" public_html || true
grep -RIn "<form\|method=\"post\"\|method='post'" public_html || true
```
