# Documentación de Boot

Este directorio concentra la documentación operativa del submódulo `Boot`.

`Boot` debe entenderse como un módulo de observabilidad/bootstrap de servidor, no como módulo runtime de aplicación. Su responsabilidad principal es generar snapshots read-only del host, persistirlos como artefactos locales, exponerlos por API/UI y enviar opcionalmente un resumen por Telegram usando primitivas de `Base`.

## Estado auditado

| Área | Estado | Nota |
|---|---|---|
| CLI `bin/boot-report` | Operable | Genera JSON, persiste `report.json`/`summary.txt` y puede imprimir por stdout. |
| Dependencia `Base` | Explícita | Bash y PHP resuelven `Base` por `BASE_DIR`, layout local o `/opt/base`. |
| Reportes | Operables | Ruta por defecto: `/var/lib/boot-report/reports/latest/report.json`. |
| Telegram | Opcional | Se controla con `BOOT_SEND_TELEGRAM`; secretos no deben versionarse. |
| API pública | Operable read-only | `health.php`, `latest.php`, `history.php`. |
| SuperAdmin | Operable read-only | Pantalla propia modularizada en partials; no ejecuta comandos del sistema. |
| Tests/smoke | Parcialmente cubiertos | Existe smoke dev, tests shell/PHP y test CLI disposable. |
| Packaging | Requiere corrección | Scripts de paquete referencian manifests que no fueron verificados en el repo. |

## Carpetas

| Carpeta | Uso |
|---|---|
| [`operacion/`](operacion/) | Arquitectura, instalación, API/UI, validación y operación diaria. |
| [`contratos/`](contratos/) | Contratos con Base, schema `report.json`, empaquetado y límites. |
| [`auditorias/`](auditorias/) | Informe de auditoría generado desde el estado actual. |
| [`cambios/`](cambios/) | Cierres documentales aplicados por este paquete. |
| [`pendientes/`](pendientes/) | Backlog vivo priorizado para dejar Boot más sólido. |

## Lectura recomendada

1. [`operacion/arquitectura.md`](operacion/arquitectura.md)
2. [`contratos/base-observabilidad.md`](contratos/base-observabilidad.md)
3. [`contratos/report-json-v1.md`](contratos/report-json-v1.md)
4. [`operacion/instalacion-systemd.md`](operacion/instalacion-systemd.md)
5. [`operacion/superadmin-api.md`](operacion/superadmin-api.md)
6. [`operacion/testing.md`](operacion/testing.md)
7. [`pendientes/README.md`](pendientes/README.md)

## Regla de operación

Boot puede observar y reportar estado del servidor. No debe convertirse en orquestador de acciones destructivas, panel de ejecución remota ni módulo runtime obligatorio del host `Pruebas`.

## Comandos base

```bash
cd submodules/Boot
chmod +x bin/* scripts/server/*.sh scripts/web/*.sh scripts/dev/*.sh test/shell/*.sh
bash scripts/dev/smoke.sh
BOOT_REPORTS_DIR=/tmp/boot-report/reports BOOT_SEND_TELEGRAM=false bin/boot-report --no-telegram --print
```

## Regla documental

Esta carpeta reemplaza documentación previa de `Boot/docs`. Si existían documentos históricos no incluidos acá, deben reubicarse manualmente solo si siguen vigentes y no contradicen el estado auditado.
