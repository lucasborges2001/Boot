# Arquitectura operativa

## Ownership

```txt
Boot = recolección, persistencia y exposición read-only de telemetría del host
Base = helpers y contratos reutilizables
Docker = telemetría y lifecycle de contenedores
securityLab = señales defensivas e inventario autorizado
Pruebas = wiring, presentación consolidada y smokes de integración
```

Boot depende únicamente de Base. No depende de Docker, securityLab ni del host `Pruebas`.

## Flujo principal

```txt
bin/boot-report
  -> resuelve y carga Base
  -> lib/shell/collect.sh
       -> collect/system.sh
       -> collect/cpu.sh
       -> collect/memory.sh
       -> collect/storage.sh
       -> collect/network.sh
  -> report.json schema v2
  -> lib/shell/render.sh
  -> lib/shell/persist.sh
       -> snapshot append-only
       -> latest atómico
       -> pruning confinado
  -> Telegram opcional
```

## Colectores

| Colector | Fuente | Regla |
|---|---|---|
| Sistema | uname, uptime, package manager, systemd, thermal | Fallback explícito; sin mutaciones. |
| CPU | `/proc/stat`, `/proc/cpuinfo` | Dos muestras para porcentaje utilizado. |
| Memoria | `/proc/meminfo`, PSI opcional | Sin contenido de procesos. |
| Filesystems | `statvfs`, mountinfo | Solo mounts allowlisted. |
| I/O disco | `/proc/diskstats` | Solo dispositivos allowlisted; contadores acumulativos. |
| Red | sysfs y snapshot previo | Solo interfaces allowlisted; rates requieren dos muestras. |

## Compatibilidad

- writer actual: schema v2;
- readers: schema v1 y v2;
- los campos v1 se mantienen;
- ausencia de métricas nuevas se normaliza como `null`, objeto vacío o lista vacía.

## Capa PHP

```txt
back/bootstrap.php
back/support/base-resolver.php
back/support/config.php
back/support/paths.php
back/support/contracts.php
back/metrics/BootReportNormalizer.php
back/metrics/BootReportReader.php
back/metrics/BootHistoryService.php
back/metrics/BootStatusService.php
```

La capa PHP lee y normaliza snapshots. No ejecuta recolección ni comandos del sistema.

## Capa web

```txt
public_html/api/{health,latest,history,summary,details}.php
public_html/superadmin/api/{probe,latest,history,summary,details}.php
public_html/superadmin/index.php
```

La capa web es read-only, responde con `no-store` y no expone rutas absolutas ni excepciones internas.

## Persistencia

- `latest/report.json` y `latest/summary.txt` se reemplazan atómicamente;
- el histórico se guarda en hijos directos por timestamp UTC;
- nombres duplicados reciben sufijo único y no sobrescriben snapshots previos;
- pruning solo considera directorios de snapshot con `report.json`;
- no sigue symlinks ni borra `latest` o carpetas ajenas;
- límites configurables por días y cantidad máxima.

## Separación de responsabilidades

| Capa | Puede hacer | No debe hacer |
|---|---|---|
| CLI | Colectar, persistir y enviar Telegram opcional. | Exponer secretos o depender de web. |
| PHP back | Leer, normalizar y calcular vistas sobre historial. | Ejecutar comandos del sistema. |
| API | Responder JSON read-only. | Mutar estado o ejecutar acciones. |
| SuperAdmin | Mostrar estado y tendencias básicas. | Orquestar operaciones productivas. |
