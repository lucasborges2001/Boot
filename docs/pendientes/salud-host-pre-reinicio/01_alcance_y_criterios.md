# Fase 01 — Alcance y criterios de salud del host

## Estado

Pendiente.

## Problema comprobado

Una actualización de kernel puede quedar parcialmente configurada por fallos de paquetes o módulos externos y, aun así, dejar archivos visibles en `/boot` y una entrada seleccionable por GRUB. El reinicio posterior puede producir una indisponibilidad evitable.

El caso de referencia es:

```text
kernel nuevo instalado parcialmente
→ DKMS falla
→ dpkg queda inconsistente
→ initramfs/GRUB se generan durante una instalación incompleta
→ el host reinicia con el kernel nuevo
→ fallo de arranque
```

## Objetivo

Extender `Boot` para que, además de observar métricas, pueda evaluar de forma read-only la salud operativa del host y responder si un reinicio es seguro.

Resultado esperado:

```text
recolección read-only
→ normalización
→ reglas verificables
→ evidencia
→ severidad
→ safe_to_reboot
→ JSON, CLI, historial, Telegram y SuperAdmin
```

## Criterios de éxito

- detectar paquetes incompletos antes de reiniciar;
- detectar fallos DKMS asociados a kernels instalados;
- comprobar kernel, módulos, initramfs, GRUB y fallback;
- diferenciar advertencia, error activo y bloqueo de reinicio;
- emitir evidencia reproducible y no sólo un resumen textual;
- no reparar, instalar, eliminar ni reconfigurar automáticamente;
- mantener compatibilidad de lectura con reportes anteriores;
- cubrir el incidente de referencia mediante fixtures y tests deterministas.

## Fuera de alcance

- ejecutar reparaciones automáticas;
- modificar GRUB, initramfs, paquetes o módulos;
- eliminar kernels antiguos;
- ejecutar `autoremove`;
- inspeccionar payloads o procesos privados;
- administrar contenedores;
- garantizar que un kernel nuevo no contenga bugs que sólo aparecen después del reinicio;
- sustituir backups, fallback de kernel o procedimientos de recuperación.

## Restricciones

- read-only por defecto;
- timeouts en todos los comandos externos;
- un dato no disponible se representa como `unknown` o `available=false`;
- no convertir ausencia de evidencia en estado saludable;
- no depender de Internet para evaluar el estado local;
- los chequeos con privilegios deben degradar a `unknown` si no pueden ejecutarse;
- no duplicar helpers genéricos de `Base`.

## Clasificación

### Boot

- colectores de salud del host;
- reglas `safe_to_reboot`;
- evidencia, severidad e historial;
- CLI, Telegram, API y SuperAdmin específicos de Boot.

### Base

- helpers genéricos de timeout, JSON, log, lock y tiempo;
- contratos transversales sólo si ya existen o se justifican para más módulos.

### Pruebas

- integración del submódulo;
- configuración del host;
- smokes end-to-end;
- documentación operativa de despliegue.

## Pendientes

- [ ] definir plataformas soportadas inicialmente;
- [ ] confirmar Ubuntu 24.04 como primera implementación;
- [ ] definir qué chequeos requieren `sudo` read-only;
- [ ] documentar amenazas y datos explícitamente no recolectados;
- [ ] fijar límites de tiempo y tamaño de logs capturados;
- [ ] decidir si el contrato se agrega a `report.json` o se expone como perfil separado;
- [ ] conservar compatibilidad de readers v1/v2.

## Criterio de cierre

La fase se considera terminada cuando existe un contrato de alcance aprobado, los no-objetivos son explícitos y ninguna tarea posterior requiere asumir permisos, plataformas o capacidades no documentadas.
