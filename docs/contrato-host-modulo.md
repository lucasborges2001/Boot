# Contrato host ↔ módulo Boot

## Clasificación esperada en `Pruebas`

Boot debe figurar como tooling opcional de servidor:

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
| Disponibilidad | Boot puede faltar sin romper el runtime de aplicación. |
| Preflight | No debe bloquear el preflight general por defecto. |
| Deploy app | No entra en deploy de aplicación. |
| Base | Consume `Base` por `BASE_DIR`, checkout vecino, layout de submódulos o `/opt/base`. |
| UI/API | Solo lectura; sin formularios destructivos ni ejecución remota. |
| Telegram | Opcional; deshabilitable con `BOOT_SEND_TELEGRAM=false` y `--no-telegram`. |
| Secretos | No versionar tokens, chat IDs ni `.env` reales. |
| Packaging | Debe generar paquetes reproducibles desde el checkout. |

## Endpoints read-only

| Endpoint | Método | Contrato |
|---|---:|---|
| `public_html/api/health.php` | GET | Health read-only del snapshot. |
| `public_html/api/latest.php` | GET | Último snapshot normalizado. |
| `public_html/api/history.php` | GET | Historial acotado. |
| `public_html/superadmin/api/latest.php` | GET | Último snapshot para SuperAdmin. |
| `public_html/superadmin/api/history.php` | GET | Historial para SuperAdmin. |
| `public_html/superadmin/api/probe.php` | GET | Probe read-only de disponibilidad. |

Shape estable de éxito:

```json
{
  "ok": true,
  "module": "boot",
  "code": "OK",
  "data": {}
}
```

Shape estable de error:

```json
{
  "ok": false,
  "module": "boot",
  "code": "NO_SNAPSHOT",
  "error": {
    "message": "No Boot snapshot available"
  }
}
```

Método inválido:

- HTTP `405`;
- header `Allow: GET`;
- `code: METHOD_NOT_ALLOWED`.

## Validación desde Boot

```bash
bash scripts/dev/smoke.sh
BOOT_REPORTS_DIR="$(mktemp -d)/reports" BOOT_SEND_TELEGRAM=false bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null
bash bin/boot-report-package
```

## Validación desde Pruebas

```bash
bash scripts/quality/audit_structure.sh ./submodules/Boot/
```

## Límites de integración

Boot no debe asumir que todos los entornos tienen:

- `sensors`;
- `systemctl` operativo;
- salida a internet;
- credenciales Telegram;
- permisos productivos sobre `/var/lib/boot-report`;
- `Base` instalado en `/opt/base` durante tests.
