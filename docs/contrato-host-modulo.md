# Contrato host ↔ módulo Boot

## Clasificación en Pruebas

Boot debe registrarse en `Pruebas/config/submodules.php` como tooling opcional de servidor:

```php
[
    'tier' => 'tooling-server-bootstrap',
    'required_for_preflight' => false,
    'include_in_app_deploy' => false,
    'tooling' => true,
    'optional' => true,
]
```

## Contrato con el host

| Punto | Contrato |
|---|---|
| Disponibilidad | Boot puede faltar sin romper el runtime de aplicación del host. |
| Preflight | No debe bloquear preflight general si no está instalado/configurado. |
| Deploy app | No entra en despliegue de aplicación por defecto. |
| Base | Debe consumir `Base` por `BASE_DIR`, checkout vecino o `/opt/base`. |
| UI/API | Solo lectura. No formularios destructivos ni ejecución de comandos. |
| Telegram | Opcional, deshabilitable con `BOOT_SEND_TELEGRAM=false` o `--no-telegram`. |
| Secretos | Nunca se versionan tokens ni chat IDs reales. |

## Artefactos contractuales

Boot produce:

```txt
reports/latest/report.json
reports/latest/summary.txt
```

Ruta base por defecto:

```txt
/var/lib/boot-report/reports
```

Ruta base configurable:

```bash
BOOT_REPORTS_DIR=/ruta/segura/reports
```

## Endpoints read-only

| Endpoint | Método | Contrato |
|---|---:|---|
| `public_html/api/health.php` | GET | Estado de lectura del snapshot. |
| `public_html/api/latest.php` | GET | Último snapshot normalizado. |
| `public_html/api/history.php` | GET | Historial acotado. |
| `public_html/superadmin/api/latest.php` | GET | Último snapshot para SuperAdmin. |
| `public_html/superadmin/api/history.php` | GET | Historial para SuperAdmin. |
| `public_html/superadmin/api/probe.php` | GET | Probe de disponibilidad read-only. |

Shape estable de éxito:

```json
{
  "ok": true,
  "module": "boot",
  "code": "boot.latest.ok",
  "data": {}
}
```

Shape estable de error:

```json
{
  "ok": false,
  "module": "boot",
  "code": "boot.latest.missing",
  "error": "No Boot snapshot available"
}
```

Métodos no permitidos deben devolver `405` y `Allow: GET`.

## Smokes seguros desde el host

Desde `Pruebas`:

```bash
bash scripts/quality/audit_structure.sh ./submodules/Boot/
```

Desde `Boot`:

```bash
bash scripts/dev/smoke.sh
BOOT_REPORTS_DIR="$(mktemp -d)/reports" BOOT_SEND_TELEGRAM=false bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null
bash bin/boot-report-package
```

## Límites de integración

Boot no debe asumir que todos los hosts tienen:

- `sensors`;
- `systemctl` operativo dentro de contenedores;
- salida a internet;
- credenciales Telegram;
- permisos sobre `/var/lib/boot-report` durante tests.

Por eso los tests deben tolerar ausencia de sensores/systemd y escribir solo en temporales.
