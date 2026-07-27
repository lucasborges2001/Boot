# Fase 02 — Paquetes y actualizaciones

## Estado

Pendiente.

## Objetivo

Detectar estados inconsistentes de `dpkg` y APT antes de considerar seguro un reinicio o una nueva actualización.

## Recolección propuesta

Comandos read-only de referencia:

```bash
dpkg --audit
apt-get check
dpkg-query -W -f='${db:Status-Abbrev}\t${binary:Package}\t${Version}\n'
apt list --upgradable
```

Los comandos deben ejecutarse con timeout, locale controlado y captura separada de `stdout`, `stderr` y código de salida.

## Datos mínimos

```json
{
  "packages": {
    "available": true,
    "manager": "apt-dpkg",
    "audit_clean": false,
    "dependency_check_ok": false,
    "incomplete": [],
    "upgradable_total": 0,
    "security_updates": 0,
    "reboot_required": false
  }
}
```

## Estados a detectar

- paquetes `iF`, `iU`, `iH`, `iW` u otros estados incompletos;
- dependencias rotas;
- configuración pendiente;
- instalación interrumpida;
- lock activo de APT/dpkg, diferenciado de corrupción;
- actualizaciones de seguridad pendientes;
- reinicio requerido;
- metapaquetes de kernel instalados pero dependencias sin configurar.

## Reglas preliminares

### BLOCK_REBOOT

- `dpkg --audit` devuelve contenido relevante;
- existen paquetes de kernel, headers o módulos en estado incompleto;
- `apt-get check` falla por dependencias rotas;
- una transacción de paquetes quedó sin configurar.

### WARNING

- hay actualizaciones pendientes con estado consistente;
- existe `reboot-required` sin evidencia de instalación incompleta;
- se detecta un lock temporal por una operación activa.

### UNKNOWN

- APT/dpkg no existen;
- el comando excede el timeout;
- faltan permisos o el formato no puede interpretarse.

## Pendientes

- [ ] implementar colector aislado para APT/dpkg;
- [ ] evitar parsear texto localizado cuando exista salida estructurada o abreviaturas estables;
- [ ] definir soporte posterior para DNF/YUM/Pacman sin degradar Ubuntu;
- [ ] normalizar estados de paquetes a un contrato interno estable;
- [ ] registrar evidencia limitada por tamaño;
- [ ] distinguir lock activo de base de datos dañada;
- [ ] agregar fixtures de `ii`, `iF`, `iU`, dependencias rotas y timeout;
- [ ] probar que el colector no escribe en cachés ni modifica el estado de APT.

## Criterios de aceptación

- un paquete `linux-image-*` en estado `iF` produce `BLOCK_REBOOT`;
- un paquete `linux-headers-*` en estado `iU` produce `BLOCK_REBOOT` cuando pertenece al kernel objetivo;
- `apt-get check` correcto no se interpreta como prueba suficiente si `dpkg --audit` falla;
- una lista de actualizaciones normal no produce error ni bloqueo;
- la ausencia del gestor se informa como `unknown`, no como `ok`.

## Criterio de cierre

La fase termina cuando los estados incompletos pueden reproducirse con fixtures y el incidente de referencia queda bloqueado antes de evaluar DKMS o GRUB.
