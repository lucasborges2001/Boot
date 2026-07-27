# Fase 04 — DKMS y módulos externos

## Estado

Pendiente.

## Objetivo

Detectar módulos externos incompatibles con kernels instalados y relacionar el fallo con el estado de paquetes y la seguridad del próximo reinicio.

## Dominios incluidos

- VirtualBox;
- NVIDIA;
- VMware;
- ZFS mediante DKMS cuando corresponda;
- drivers Wi-Fi u otros módulos externos registrados;
- cualquier módulo informado por `dkms status`.

No se deben incorporar reglas codificadas únicamente para VirtualBox. El incidente de VirtualBox es un fixture de referencia, no el modelo completo.

## Recolección propuesta

```bash
dkms status
find /var/lib/dkms -maxdepth 5 -type f -name make.log
find /var/crash -maxdepth 1 -type f -name '*dkms*.crash'
find /lib/modules -path '*/updates/dkms/*' -type f
```

La lectura de logs debe estar limitada por cantidad de líneas y bytes. No se deben exponer rutas privadas innecesarias ni contenido ajeno al build.

## Datos mínimos

```json
{
  "dkms": {
    "available": true,
    "modules": [
      {
        "name": "virtualbox",
        "version": "7.0.16",
        "kernel": "7.0.0-28-generic",
        "state": "build_failed",
        "error_class": "modpost_namespace",
        "evidence": []
      }
    ]
  }
}
```

## Clasificación de errores

- compilación fallida;
- headers ausentes;
- toolchain ausente o incompatible;
- error de `modpost`;
- firma o Secure Boot;
- módulo construido pero no instalado;
- módulo instalado para el kernel actual pero no para el objetivo;
- estado desconocido por timeout o permisos;
- reporte de crash residual sin fallo activo.

## Reglas preliminares

### BLOCK_REBOOT

- un módulo DKMS requerido falló para el kernel objetivo y la configuración del kernel quedó incompleta;
- el kernel objetivo depende de un módulo necesario para almacenamiento, filesystem, red esencial o GPU requerida para operar el host;
- existe una transacción activa de kernel bloqueada por DKMS.

### ERROR

- un módulo externo utilizado actualmente no está disponible para el kernel objetivo;
- DKMS informa estado distinto de `installed` para el objetivo;
- el build log contiene un error fatal reproducible.

### WARNING

- un módulo opcional no podrá utilizarse después del reinicio;
- existen crash reports residuales sin fallo actual;
- un módulo está instalado para el kernel actual pero aún no fue evaluado para un kernel nuevo no seleccionado.

## Requisito de contexto

No todo fallo DKMS debe bloquear el reinicio. La regla necesita combinar:

```text
módulo afectado
+ kernel objetivo
+ estado de paquetes
+ criticidad del módulo
+ disponibilidad de fallback
```

Debe existir una allowlist/configuración para marcar módulos como:

- `required`;
- `important`;
- `optional`;
- `ignored`.

La configuración productiva no debe inventarse ni versionarse con datos específicos del host.

## Pendientes

- [ ] implementar parser estable para `dkms status`;
- [ ] correlacionar módulo y kernel objetivo;
- [ ] definir catálogo extensible de clases de error;
- [ ] agregar límites de lectura de `make.log`;
- [ ] separar warnings de compilador de errores fatales;
- [ ] soportar Secure Boot y estados de firma;
- [ ] definir criticidad configurable por módulo;
- [ ] agregar fixture VirtualBox 7.0.16 contra kernel 7.0 con error `modpost`;
- [ ] agregar fixtures de NVIDIA, headers ausentes y timeout;
- [ ] evitar almacenar claves, certificados o contenido sensible.

## Criterios de aceptación

- el fixture VirtualBox/kernel 7.0 produce un hallazgo DKMS determinista;
- el warning de versión de compilador no oculta el error fatal posterior;
- un crash report existente no se interpreta por sí solo como fallo activo;
- un módulo opcional fallido puede producir `ERROR` sin bloquear cuando el kernel queda consistente;
- un módulo requerido faltante para el kernel objetivo produce `BLOCK_REBOOT`.

## Criterio de cierre

La fase termina cuando los fallos DKMS se correlacionan con kernels concretos, tienen evidencia limitada y participan en reglas de severidad sin depender del nombre de un único proveedor.
