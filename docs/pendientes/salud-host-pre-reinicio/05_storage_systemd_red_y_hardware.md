# Fase 05 — Storage, systemd, red y hardware

## Estado

Pendiente.

## Objetivo

Ampliar la evaluación preventiva más allá del caso kernel/DKMS para detectar degradaciones del mismo tipo: visibles antes de un reinicio, una actualización o una indisponibilidad.

## Storage y filesystem

Pendientes:

- [ ] detectar filesystems montados read-only inesperadamente;
- [ ] revisar capacidad e inodos de `/`, `/boot`, EFI y mounts allowlisted;
- [ ] identificar errores recientes de I/O, ext4, XFS, Btrfs, NVMe y SATA;
- [ ] integrar SMART/NVMe read-only cuando las herramientas estén disponibles;
- [ ] distinguir contador histórico de alerta activa;
- [ ] detectar montajes declarados pero fallidos;
- [ ] evitar ejecutar `fsck` sobre filesystems montados;
- [ ] representar falta de permisos como `unknown`.

Comandos de referencia:

```bash
findmnt --json
df -P
df -Pi
journalctl -k -p warning..alert
smartctl -H -A <device>
nvme smart-log <device>
```

## systemd y arranque

Pendientes:

- [ ] conservar `systemctl --failed`;
- [ ] agregar `systemctl is-system-running`;
- [ ] clasificar servicios críticos, importantes y opcionales;
- [ ] detectar ciclos de reinicio y fallos repetidos;
- [ ] comparar boot actual con boot anterior;
- [ ] evitar considerar mensajes conocidos de GNOME/Bluetooth como críticos sin contexto;
- [ ] emitir evidencia con unidad, estado y timestamp.

## Logs del kernel y hardware

Pendientes:

- [ ] detectar OOM kills;
- [ ] detectar MCE/EDAC y errores de memoria;
- [ ] detectar errores PCIe persistentes;
- [ ] detectar thermal throttling y temperaturas críticas;
- [ ] detectar resets o errores del controlador NVMe/SATA;
- [ ] limitar la ventana temporal y deduplicar mensajes repetidos;
- [ ] permitir suppressions explícitas y auditables.

## Red, DNS y hora

Pendientes:

- [ ] separar link, dirección IP, ruta por defecto, DNS y acceso a repositorios;
- [ ] comprobar sincronización horaria;
- [ ] permitir targets configurables sin convertir Internet en requisito de salud local;
- [ ] distinguir DNS roto de red caída;
- [ ] no registrar payloads, conexiones ni sockets de procesos.

Comandos de referencia:

```bash
ip -json address
ip -json route
getent hosts <target>
timedatectl show
systemctl is-active systemd-resolved NetworkManager systemd-networkd
```

## Memoria y presión

Boot ya observa RAM, swap y PSI. Falta convertir tendencias en reglas operativas:

- [ ] detectar presión sostenida y no sólo porcentaje instantáneo;
- [ ] detectar swap saturada;
- [ ] correlacionar OOM con presión de memoria;
- [ ] evitar bloquear reinicio por un pico aislado;
- [ ] definir ventanas y umbrales configurables.

## Docker y virtualización

Boot no debe inspeccionar internals de contenedores ni asumir responsabilidad sobre su dominio.

Permitido:

- observar `docker.service` como unidad systemd;
- informar módulos de virtualización mediante DKMS;
- detectar que una capacidad externa quedará no disponible.

Fuera de alcance:

- health interno de contenedores;
- limpieza de imágenes, redes o volúmenes;
- gestión de máquinas virtuales;
- lectura de payloads de aplicaciones.

## Reglas preliminares

### BLOCK_REBOOT

- filesystem raíz read-only inesperadamente;
- errores activos de almacenamiento que comprometen lectura de `/` o `/boot`;
- partición de arranque sin capacidad para completar una transacción pendiente;
- dependencia crítica de red/almacenamiento no disponible y sin fallback operativo.

### CRITICAL

- SMART/NVMe informa condición crítica;
- OOM repetido con degradación activa;
- temperatura o throttling fuera de límites configurados;
- servicios críticos fallidos.

### WARNING

- DNS externo no disponible con red local funcional;
- servicios opcionales fallidos;
- temperatura elevada pero dentro del rango operativo;
- errores históricos sin repetición reciente.

## Criterios de aceptación

- cada dominio puede quedar `unknown` sin invalidar los demás;
- los errores benignos conocidos no producen `critical` por coincidencia textual aislada;
- los comandos privilegiados son read-only y tienen timeout;
- la salida conserva evidencia suficiente para reproducir el diagnóstico;
- ninguna regla ejecuta acciones correctivas.

## Criterio de cierre

La fase termina cuando Boot puede distinguir degradación activa, advertencia operativa y falta de evidencia en almacenamiento, servicios, red, memoria y hardware.
