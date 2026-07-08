# Estructura del módulo Boot

## Estado

`Boot` es un submódulo de tooling opcional para bootstrap y observabilidad de servidor. No es un módulo runtime obligatorio del host `Pruebas`.

| Campo | Valor esperado |
|---|---|
| Tipo | `tooling-server-bootstrap` |
| Dependencia principal | `Base` |
| `required_for_preflight` | `false` |
| `include_in_app_deploy` | `false` |
| Operación UI/API | read-only |
| Salida principal | snapshots locales `report.json` y `summary.txt` |

## Responsabilidad

Boot debe:

- generar snapshots read-only del host;
- persistir artefactos bajo `BOOT_REPORTS_DIR`, por defecto `/var/lib/boot-report/reports`;
- mantener `latest/report.json` y `latest/summary.txt` como contrato estable;
- exponer API y SuperAdmin read-only;
- enviar Telegram solo si está configurado y habilitado;
- poder verificarse con smokes sin Telegram real.

Boot no debe:

- ejecutar acciones destructivas desde UI/API;
- modificar configuración del host desde endpoints web;
- bloquear el preflight general de `Pruebas`;
- entrar en despliegues de aplicación por defecto;
- versionar secretos ni depender de `.env` reales para tests.

## Estructura relevante

| Ruta | Responsabilidad |
|---|---|
| `bin/boot-report` | Entrada CLI operativa. Resuelve `Base`, genera snapshot, persiste y opcionalmente envía Telegram. |
| `lib/shell/collect.sh` | Recolección vigente de métricas para runtime CLI. |
| `lib/shell/render.sh` | Render vigente de resumen y Telegram para runtime CLI. |
| `lib/shell/persist.sh` | Persistencia vigente de `report.json` y `summary.txt`. |
| `lib/render.sh` | Agregador legacy compatible dividido en `lib/render/*.sh`. |
| `lib/system.sh` | Agregador legacy compatible dividido en `lib/system/*.sh`. |
| `back/` | Lectores, normalizadores y servicios PHP read-only. |
| `public_html/api/` | API pública read-only con contrato JSON estable. |
| `public_html/superadmin/` | Vista SuperAdmin read-only. |
| `scripts/dev/smoke.sh` | Smoke seguro sin Telegram real. |
| `scripts/server/test-production.sh` | Test manual productivo, fuera de smoke automático. |

## Contrato de salida

```txt
/var/lib/boot-report/reports/latest/report.json
/var/lib/boot-report/reports/latest/summary.txt
```

El path real puede cambiar con `BOOT_REPORTS_DIR`, pero la estructura relativa `latest/report.json` y `latest/summary.txt` debe conservarse.

## Runtime vigente

La ruta vigente del runtime Bash es:

```txt
bin/boot-report
  -> lib/shell/collect.sh
  -> lib/shell/render.sh
  -> lib/shell/persist.sh
```

`lib/render.sh` y `lib/system.sh` quedan como compatibilidad legacy modularizada. No son el camino operativo principal del CLI actual.

## Relación con Base

Boot depende de `Base` para helpers shell y contratos PHP compartidos. La resolución compatible contempla:

1. `BASE_DIR` explícito;
2. `../Base` al lado del checkout Boot;
3. layout de submódulos dentro de `Pruebas`;
4. `/opt/base` en instalación de servidor.

## Criterio de operación segura

Todo test automático debe correr con directorios temporales y Telegram deshabilitado:

```bash
BOOT_REPORTS_DIR="$(mktemp -d)/reports" \
BOOT_SEND_TELEGRAM=false \
bin/boot-report --no-telegram --print
```
