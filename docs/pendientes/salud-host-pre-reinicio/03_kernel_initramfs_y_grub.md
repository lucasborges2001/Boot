# Fase 03 — Kernel, initramfs y GRUB

## Estado

Pendiente.

## Objetivo

Evaluar la cadena de arranque futura, no sólo el kernel que está ejecutándose actualmente.

## Problema

`uname -r` confirma el kernel actual, pero no demuestra que el kernel seleccionado en el próximo arranque tenga paquetes, módulos e initramfs consistentes.

## Recolección propuesta

- kernel en ejecución;
- imágenes de kernel instaladas;
- estado de paquetes por versión;
- directorios presentes en `/lib/modules`;
- archivos `vmlinuz`, `initrd.img`, `config` y `System.map`;
- tamaño, propietario y fecha de cada initramfs;
- configuración generada por GRUB;
- kernel que GRUB seleccionaría por defecto;
- existencia de al menos un kernel anterior consistente;
- espacio e inodos disponibles en `/boot` y EFI.

Comandos de referencia:

```bash
uname -r
dpkg-query -W 'linux-image-*' 'linux-modules-*'
find /boot -maxdepth 1 -type f
find /lib/modules -mindepth 1 -maxdepth 1 -type d
grub-editenv list
grep -E "^menuentry |^submenu " /boot/grub/grub.cfg
findmnt / /boot /boot/efi
df -P /boot /boot/efi
df -Pi /boot /boot/efi
```

La implementación no debe ejecutar `update-grub` ni `update-initramfs`.

## Modelo preliminar

```json
{
  "boot_chain": {
    "running_kernel": "6.17.0-40-generic",
    "target_kernel": "7.0.0-28-generic",
    "target_status": "incomplete",
    "initramfs": {
      "present": true,
      "size_bytes": 0,
      "modules_tree_present": true
    },
    "fallback": {
      "available": true,
      "kernel": "6.17.0-40-generic"
    }
  }
}
```

## Reglas preliminares

### BLOCK_REBOOT

- el kernel objetivo tiene paquetes incompletos;
- falta su `vmlinuz` o `initrd.img`;
- falta `/lib/modules/<kernel>`;
- GRUB seleccionaría un kernel inconsistente;
- no existe ningún fallback consistente;
- `/boot` o EFI están sin espacio suficiente para completar operaciones pendientes;
- la raíz configurada para el arranque no puede relacionarse con un dispositivo existente.

### ERROR

- initramfs anormalmente pequeño respecto de la misma familia de kernels;
- archivos del kernel no coinciden con paquetes instalados;
- GRUB contiene entradas obsoletas o no puede inspeccionarse;
- `/boot` está por encima del umbral crítico.

### WARNING

- kernel actual distinto del objetivo, con ambos consistentes;
- fallback único sin redundancia adicional;
- `/boot` cerca del umbral preventivo.

## Pendientes

- [ ] definir cómo resolver de forma segura el kernel objetivo de GRUB;
- [ ] soportar `GRUB_DEFAULT=saved`, índices y nombres de entrada;
- [ ] validar UUID de raíz sin asumir `/dev/nvme0n1p2`;
- [ ] definir umbrales por porcentaje y espacio absoluto para `/boot`;
- [ ] establecer comparación de tamaño de initramfs sin falsos positivos;
- [ ] identificar kernels instalados, eliminados con configuración residual y kernels utilizables;
- [ ] crear fixtures con initramfs ausente, GRUB inconsistente y fallback válido;
- [ ] probar sistemas sin partición `/boot` separada;
- [ ] documentar limitaciones con systemd-boot y otros bootloaders.

## Criterios de aceptación

- un kernel objetivo incompleto produce `BLOCK_REBOOT` aunque exista `initrd.img`;
- un kernel objetivo consistente con fallback válido no produce bloqueo;
- un archivo residual de un paquete `rc` no se considera kernel utilizable;
- el colector no modifica GRUB ni monta particiones;
- bootloader no soportado produce `unknown` con evidencia.

## Criterio de cierre

La fase termina cuando Boot puede describir la cadena de arranque prevista, identificar un fallback real y bloquear un kernel objetivo inconsistente sin ejecutar reparaciones.
