# Boot

`Boot` es un submódulo de observabilidad del servidor dependiente únicamente de `Base`.
Genera snapshots read-only del host, mantiene `latest` e historial local controlado, calcula tendencias básicas, envía opcionalmente un resumen por Telegram y expone API/UI para SuperAdmin.

## Responsabilidad

Boot conserva lógica específica de telemetría host:

- hostname, kernel y uptime;
- CPU utilizada, load average, CPUs lógicas y distribución user/system/idle/iowait/steal;
- memoria, swap y presión PSI cuando existe;
- capacidad e inodos por filesystem allowlisted;
- contadores opcionales de I/O por dispositivo allowlisted;
- contadores y tasas de red por interfaz allowlisted;
- updates pendientes, reboot requerido y servicios systemd fallidos;
- temperatura cuando existe;
- persistencia atómica, historial, retención y lectura read-only;
- tendencias de CPU, RAM, swap, disco y red calculadas sobre al menos dos muestras;
- formatter de Telegram específico del reporte Boot.

No implementa helpers genéricos de env, JSON, log, lock, time ni Telegram. Eso vive en `Base/lib/shell` y `Base/back`.

Boot no observa contenedores, no inspecciona payloads, no controla systemd y no ejecuta comandos desde PHP web.

## Compatibilidad

- escritura actual: `schema_version=2`;
- lectura soportada: `schema_version=1` y `schema_version=2`;
- los campos v1 permanecen disponibles dentro de `server`, `metrics`, `updates`, `services`, `telegram` y `artifacts`;
- los fixtures no sustituyen snapshots runtime salvo `BOOT_ALLOW_SAMPLE_REPORTS=true` o configuración explícita del directorio sample.

## Uso rápido

```bash
cd ~/Escritorio/Proyectos/Pruebas/submodules/Boot
BASE_DIR=../Base bash scripts/dev/smoke.sh

BOOT_REPORTS_DIR="$(mktemp -d)/reports" \
BOOT_SEND_TELEGRAM=false \
BOOT_FILESYSTEM_ALLOWLIST=/ \
bin/boot-report --no-telegram --print | python3 -m json.tool
```

## Configuración detallada

```env
BOOT_TELEMETRY_ENABLED=true
BOOT_REPORTS_DIR=/var/lib/boot-report/reports
BOOT_HISTORY_RETENTION_DAYS=30
BOOT_HISTORY_MAX_FILES=50000
BOOT_FILESYSTEM_ALLOWLIST=/,/var
BOOT_FILESYSTEM_EXCLUDELIST=/proc,/sys,/dev,/run
BOOT_NETWORK_INTERFACE_ALLOWLIST=eth0
BOOT_DISK_DEVICE_ALLOWLIST=sda
BOOT_CPU_SAMPLE_INTERVAL_SECONDS=0.2
BOOT_COMMAND_TIMEOUT_SECONDS=5
BOOT_INCLUDE_LAN_IP=true
BOOT_ALLOW_SAMPLE_REPORTS=false
```

Las allowlists productivas no se versionan. Una allowlist vacía deshabilita el detalle correspondiente.

## Validación

- CI parcial: `.github/workflows/boot-static-ci.yml`;
- smoke integrado con Base: `BASE_DIR=../Base bash scripts/dev/smoke.sh`;
- testing detallado: [`docs/operacion/testing.md`](docs/operacion/testing.md).

El CI parcial valida sintaxis, colectores aislados, frontera web read-only y packaging. La suite PHP completa requiere acceso al repositorio privado `Base`.

## Contratos principales

- último JSON runtime: `latest/report.json` dentro de `BOOT_REPORTS_DIR`;
- último resumen runtime: `latest/summary.txt`;
- schema vigente: [`docs/contratos/report-json-v2.md`](docs/contratos/report-json-v2.md);
- compatibilidad v1: [`docs/contratos/report-json-v1.md`](docs/contratos/report-json-v1.md);
- API: [`docs/contratos/api-json-readonly.md`](docs/contratos/api-json-readonly.md);
- API pública: `public_html/api/{health,latest,history,summary,details}.php`;
- SuperAdmin: `public_html/superadmin/index.php`.
