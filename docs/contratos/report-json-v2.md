# Contrato `report.json` v2

## Estado

Contrato implementado de forma aditiva sobre v1.

Boot emite `schema_version=2`, conserva los campos públicos de v1 y agrega telemetría host detallada. Los readers PHP aceptan versiones `1` y `2`.

## Invariantes

- `module` es siempre `boot`.
- `generated_at` usa ISO 8601 UTC.
- un valor no disponible se representa con `null`, un objeto vacío o `available=false`; no se inventan ceros salvo contadores válidos;
- ninguna tasa de red se calcula con una sola muestra;
- `ip_wan` permanece `null`;
- no se recolectan payloads, sockets, comandos, variables de procesos ni contenido de memoria;
- filesystems, interfaces y dispositivos de I/O detallados requieren allowlist.

## Compatibilidad v1

Se conservan:

```json
{
  "server": {
    "hostname": "server-01",
    "kernel": "6.x",
    "uptime_seconds": 86400,
    "ip_lan": null,
    "ip_wan": null
  },
  "metrics": {
    "cpu_load_1m": 0.61,
    "cpu_load_5m": 0.44,
    "cpu_load_15m": 0.32,
    "ram_used_percent": 58.2,
    "disk_root_used_percent": 72.0,
    "temperature_c": 48.0
  },
  "updates": {},
  "services": {},
  "telegram": {},
  "artifacts": {}
}
```

Los campos nuevos dentro de `metrics` son `cpu_used_percent` y `swap_used_percent`.

## CPU

```json
{
  "cpu": {
    "available": true,
    "source": "procfs",
    "logical": 4,
    "sample_window_seconds": 0.2,
    "used_percent": 31.4,
    "time_percent": {
      "user": 20.0,
      "system": 8.0,
      "idle": 66.6,
      "iowait": 2.0,
      "steal": 3.4
    },
    "counters_jiffies": {}
  }
}
```

`used_percent` y `time_percent` se calculan mediante dos lecturas de `/proc/stat`. Los contadores acumulativos se expresan en jiffies y no se interpretan como segundos.

## Memoria y swap

Todos los tamaños se expresan en bytes.

```json
{
  "memory": {
    "available": true,
    "total_bytes": 8589934592,
    "available_bytes": 3590594560,
    "used_bytes": 4999340032,
    "used_percent": 58.2,
    "swap_total_bytes": 2147483648,
    "swap_used_bytes": 85899346,
    "swap_used_percent": 4.0,
    "pressure": null
  }
}
```

`pressure` solo aparece cuando `/proc/pressure/memory` es legible. No se inspeccionan procesos.

## Filesystems

`filesystems` contiene únicamente mounts configurados en `BOOT_FILESYSTEM_ALLOWLIST` que no estén excluidos.

Cada elemento declara capacidad, espacio e inodos. Los tamaños usan bytes y los porcentajes usan escala `0..100`.

Pseudo-filesystems y mounts no legibles se omiten o se marcan con `available=false`.

## I/O de disco

`disk_io` solo se habilita cuando `BOOT_DISK_DEVICE_ALLOWLIST` contiene dispositivos explícitos.

Los valores son contadores acumulativos de operaciones, bytes e `io_time_ms`. Boot no calcula tasas de I/O en esta versión y no agrega dispositivos no allowlisted para evitar doble conteo en stacks LVM, RAID o device mapper.

## Red

`network_interfaces` solo contiene interfaces de `BOOT_NETWORK_INTERFACE_ALLOWLIST`.

Cada elemento conserva contadores acumulativos RX/TX, errores y drops. Las tasas se generan únicamente cuando existe un snapshot previo válido de la misma interfaz.

Estados posibles de `rate_status`:

- `insufficient_samples`;
- `ok`;
- `invalid_interval`;
- `incomplete_counters`;
- `counter_reset`;
- `reboot_detected`;
- `interface_unavailable`.

Ante reboot o disminución de cualquier contador, `rates` queda en `null`; nunca se emite un pico artificial.

## Persistencia

- `latest/report.json` y `latest/summary.txt` se reemplazan mediante `mv` atómico;
- el histórico es append-only por timestamp UTC;
- snapshots corruptos se omiten durante lectura;
- pruning opera solo sobre hijos directos con nombre de snapshot y `report.json` válido;
- symlinks, `latest` y directorios ajenos no se borran;
- límites: `BOOT_HISTORY_RETENTION_DAYS` y `BOOT_HISTORY_MAX_FILES`.

## Exposición API

La normalización API:

- reemplaza rutas absolutas de artefactos por `latest/report.json` y `latest/summary.txt`;
- no expone rutas del reader ni del histórico;
- fuerza `ip_wan=null`;
- valida nombres de interfaces;
- agrega metadata de compatibilidad para schema v1/v2.
