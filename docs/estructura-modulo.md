# Estructura del módulo Boot

## Clasificación

| Campo | Valor |
|---|---|
| Tipo | `tooling-server-bootstrap` |
| Host esperado | `Pruebas/submodules/Boot` |
| Dependencia principal | `Base` |
| Runtime de aplicación | No |
| Preflight obligatorio | No |
| Deploy app | No |
| UI/API | Read-only |
| Artefactos principales | `report.json`, `summary.txt`, tarballs de packaging |

## Responsabilidad

Boot debe:

- generar snapshots read-only del servidor;
- persistir `latest/report.json` y `latest/summary.txt` bajo `BOOT_REPORTS_DIR`;
- exponer estado por API pública y SuperAdmin sin ejecución de comandos remotos;
- enviar Telegram solo si está configurado y habilitado;
- empaquetar instalación server/web de forma reproducible;
- validarse con smokes sin secretos reales.

Boot no debe:

- bloquear el preflight general de `Pruebas`;
- ejecutar acciones destructivas desde UI/API;
- modificar configuración productiva desde endpoints web;
- versionar tokens, chat IDs ni `.env` reales;
- depender de Telegram para que el CLI genere JSON.

## Estructura relevante

| Ruta | Responsabilidad |
|---|---|
| `bin/boot-report` | Entrada CLI operativa. Genera snapshot, persiste artefactos y opcionalmente envía Telegram. |
| `bin/boot-report-package` | Orquestador de paquetes server y web. |
| `lib/shell/collect.sh` | Recolección vigente de métricas. Única deuda estructural por tamaño. |
| `lib/shell/render.sh` | Render vigente de summary/Telegram. |
| `lib/shell/persist.sh` | Persistencia de latest e historial. |
| `lib/render.sh`, `lib/render/*.sh` | Compatibilidad legacy modularizada. |
| `lib/system.sh`, `lib/system/*.sh` | Compatibilidad legacy modularizada. |
| `back/` | Bootstrap PHP, resolución de Base, normalización y servicios read-only. |
| `public_html/api/` | API pública read-only con contrato JSON visible. |
| `public_html/superadmin/` | UI/API SuperAdmin read-only. |
| `scripts/dev/smoke.sh` | Smoke seguro de desarrollo. |
| `scripts/server/test-production.sh` | Test productivo manual, fuera de smoke automático. |
| `test/php/`, `test/shell/` | Contratos PHP y shell. |

## Runtime vigente

```txt
bin/boot-report
  -> lib/shell/collect.sh
  -> lib/shell/render.sh
  -> lib/shell/persist.sh
```

`lib/render.sh` y `lib/system.sh` no son el camino principal del CLI actual; quedan como agregadores chicos de compatibilidad.

## Artefactos contractuales

```txt
reports/latest/report.json
reports/latest/summary.txt
```

Ruta default:

```txt
/var/lib/boot-report/reports
```

Ruta configurable:

```bash
BOOT_REPORTS_DIR=/ruta/segura/reports
```

## Criterio de operación segura

Todo test automático debe poder correr así:

```bash
BOOT_REPORTS_DIR="$(mktemp -d)/reports" \
BOOT_SEND_TELEGRAM=false \
bin/boot-report --no-telegram --print | python3 -m json.tool >/dev/null
```
