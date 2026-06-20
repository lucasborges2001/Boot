# Instalación web

Copiar `back`, `config`, `database`, `public_html`, `docs` y `README.md` al host web.

Endpoints:

- `/api/health.php`
- `/api/latest.php`
- `/api/history.php`
- `/superadmin/index.php`

El servidor web debe tener permisos de lectura sobre `BOOT_REPORTS_DIR` o usar `var/sample-reports` como fallback de desarrollo.
