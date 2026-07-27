# Fase 07 — CLI, historial, alertas e integración

## Estado

Pendiente.

## Objetivo

Integrar la evaluación de salud con las capacidades existentes de Boot sin mezclar recolección, decisión y presentación.

## CLI propuesta

Alternativas a resolver:

### Opción A — Perfil de `boot-report`

```bash
bin/boot-report --profile pre-reboot --print
```

Ventajas:

- reutiliza persistencia y configuración existentes;
- unifica snapshots.

Riesgos:

- puede aumentar tiempos y permisos del reporte normal;
- mezcla telemetría periódica con auditoría profunda.

### Opción B — CLI complementaria

```bash
bin/boot-health pre-reboot --json
bin/boot-health check --profile deep
```

Ventajas:

- exit codes y operación evaluada explícitos;
- permite chequeos más costosos bajo demanda.

Riesgos:

- requiere compartir contrato y persistencia sin duplicar lógica.

## Recomendación preliminar

Mantener `boot-report` como snapshot periódico y agregar `boot-health` como orquestador de perfiles. Ambos deben reutilizar colectores y normalización comunes.

La decisión final requiere revisar compatibilidad, packaging y operación productiva.

## Historial

Pendientes:

- [ ] almacenar findings estructurados en snapshots;
- [ ] registrar aparición, persistencia y resolución de anomalías;
- [ ] evitar crecimiento ilimitado de evidencia y logs;
- [ ] mantener persistencia atómica y pruning confinado;
- [ ] distinguir reboot real de reset de contadores;
- [ ] comparar kernel objetivo y estado de paquetes entre muestras;
- [ ] preservar lectura de reportes v1/v2.

## Telegram

Pendientes:

- [ ] resumen específico para `BLOCK_REBOOT`;
- [ ] incluir IDs de hallazgo y evidencia mínima;
- [ ] evitar enviar logs completos;
- [ ] no repetir alertas idénticas en cada ejecución;
- [ ] notificar resolución de un bloqueo;
- [ ] mantener Telegram como canal opcional, no fuente de verdad.

Ejemplo:

```text
Boot: reinicio bloqueado
Host: ubuntudev
Kernel actual: 6.17.0-40-generic
Kernel objetivo: 7.0.0-28-generic
Hallazgo: kernel.dkms_failed
Módulo: virtualbox/7.0.16
```

## API y SuperAdmin

Pendientes:

- [ ] exponer decisión global y findings normalizados;
- [ ] filtrar rutas absolutas y evidencia sensible;
- [ ] vista de operación `safe_to_reboot`;
- [ ] detalle por paquete, kernel y módulo;
- [ ] historial de bloqueos y resoluciones;
- [ ] compatibilidad de endpoints actuales;
- [ ] frontera web estrictamente read-only;
- [ ] no ejecutar comandos desde PHP web.

## systemd timer

Pendientes:

- [ ] mantener reporte periódico ligero;
- [ ] decidir frecuencia del perfil de salud;
- [ ] ejecutar `pre-reboot` bajo demanda o mediante hook controlado;
- [ ] evitar bloquear `shutdown` sin una política explícita;
- [ ] no crear un wrapper que impida recuperación manual;
- [ ] registrar timeout y resultado del chequeo.

## Integración con Base

Base debe proveer sólo capacidades transversales ya existentes:

- env;
- log;
- JSON;
- lock;
- time;
- Telegram.

Pendientes:

- [ ] comprobar si hace falta un contrato de health compartido;
- [ ] no mover reglas específicas de kernel/DKMS a Base;
- [ ] mantener Boot dependiente únicamente de Base.

## Integración con Pruebas

Debe realizarse en una fase y PR separados después de validar Boot:

- adapter/configuración;
- actualización del gitlink;
- smoke integrado;
- panel host si corresponde;
- documentación operativa.

No se modifica `Pruebas` durante la implementación interna de Boot.

## Criterios de aceptación

- la CLI devuelve un exit code útil para automatización;
- API, Telegram y SuperAdmin muestran la misma decisión normalizada;
- la interfaz web no ejecuta comandos del host;
- historial y latest siguen siendo atómicos;
- un fallo de Telegram no altera el resultado de salud;
- el perfil periódico puede desactivar chequeos costosos.

## Criterio de cierre

La fase termina cuando existe una decisión documentada sobre CLI/perfiles y todos los consumidores utilizan el mismo contrato normalizado sin duplicar reglas.
