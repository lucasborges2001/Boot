# Fase 08 — Pruebas, despliegue y cierre

## Estado

Pendiente.

## Objetivo

Demostrar que la evaluación de salud detecta fallos reales sin modificar el host y sin introducir falsos bloqueos frecuentes.

## Estrategia de pruebas

El motor de reglas debe probarse principalmente con fixtures. Los tests no deben romper paquetes, kernels o filesystems de una máquina real.

## Fixtures mínimos

### Paquetes

- [ ] todos los paquetes en estado `ii`;
- [ ] `linux-image` en estado `iF`;
- [ ] `linux-headers` en estado `iU`;
- [ ] dependencias rotas;
- [ ] lock temporal de APT;
- [ ] gestor no disponible.

### Kernel y arranque

- [ ] kernel actual consistente;
- [ ] kernel objetivo consistente con fallback;
- [ ] initramfs ausente;
- [ ] initramfs anormalmente pequeño;
- [ ] `/lib/modules/<kernel>` ausente;
- [ ] GRUB apunta a kernel inconsistente;
- [ ] no existe fallback;
- [ ] `/boot` lleno.

### DKMS

- [ ] VirtualBox 7.0.16 con error de namespaces contra kernel 7.0;
- [ ] headers ausentes;
- [ ] error de firma/Secure Boot;
- [ ] módulo opcional fallido;
- [ ] módulo requerido fallido;
- [ ] crash report residual sin fallo activo.

### Host general

- [ ] filesystem raíz read-only;
- [ ] NVMe con warning crítico;
- [ ] servicio crítico fallido;
- [ ] servicio opcional fallido;
- [ ] OOM repetido;
- [ ] DNS roto con red local funcional;
- [ ] timeout de un colector;
- [ ] permisos insuficientes.

## Caso de aceptación principal

Entrada:

```text
kernel actual: 6.17.0-40-generic
kernel objetivo: 7.0.0-28-generic
linux-image objetivo: iF
linux-headers objetivo: iF
dkms virtualbox: build failed
fallback: disponible
```

Salida esperada:

```json
{
  "safe_to_reboot": false,
  "highest_severity": "block"
}
```

Debe incluir findings separados para paquetes incompletos y DKMS, sin depender del texto localizado de APT.

## Tests propuestos

- [ ] tests shell de cada colector con roots/commands inyectables;
- [ ] tests Python del normalizador;
- [ ] tests unitarios de cada regla;
- [ ] tests de reglas compuestas;
- [ ] tests de compatibilidad de schema;
- [ ] tests PHP de readers, API y SuperAdmin;
- [ ] smoke CLI disposable;
- [ ] auditoría de frontera web read-only;
- [ ] packaging server/web;
- [ ] `git diff --check` y auditor estructural desde Pruebas.

## Comandos de verificación previstos

```bash
BASE_DIR=../Base bash scripts/dev/smoke.sh
bash test/shell/boot_health_collect_test.sh
python3 -m unittest discover -s test/python
php test/php/BootHealthContractTest.php
php test/php/BootHealthApiTest.php
bash bin/boot-report-package
git diff --check
git status --short --branch
```

Los nombres definitivos deben ajustarse a la estructura implementada.

## Pruebas con host real

Sólo después de pasar fixtures y smokes:

- [ ] ejecutar perfil normal en Ubuntu 24.04 saludable;
- [ ] ejecutar perfil `pre-reboot` antes de una actualización real;
- [ ] comprobar timeout y permisos sin sudo;
- [ ] comprobar lectura con sudo read-only;
- [ ] validar un kernel nuevo manteniendo fallback;
- [ ] comprobar que no se escribieron paquetes, GRUB, initramfs ni systemd;
- [ ] verificar historial, Telegram y SuperAdmin.

## Despliegue gradual

1. CLI manual sin persistencia productiva.
2. Persistencia local con Telegram deshabilitado.
3. Timer en un host controlado.
4. Telegram y SuperAdmin.
5. Integración en `Pruebas` mediante PR separado.

## Rollback

- deshabilitar el perfil de salud;
- retirar el timer específico;
- mantener lectura de reportes anteriores;
- revertir cambios de Boot sin modificar estado del host;
- conservar snapshots para diagnóstico, sujetos a retención.

## Condición de terminado

El proyecto se declara terminado cuando:

1. el incidente de referencia produce `BLOCK_REBOOT`;
2. un host saludable produce `safe_to_reboot=true`;
3. los colectores son read-only y tienen timeout;
4. `unknown` se conserva explícitamente;
5. existen fixtures para cada regla crítica;
6. API/UI no ejecutan comandos;
7. v1/v2 continúan siendo legibles;
8. el smoke integrado con Base pasa;
9. la documentación operativa describe límites y recuperación;
10. la integración con `Pruebas` queda como cambio separado.

## Decisión de cierre

**Recomiendo:** cerrar únicamente cuando el caso real y los fixtures saludables estén cubiertos.

**No recomiendo:** habilitar bloqueo automático de shutdown en la primera versión.

**Razón principal:** la herramienta debe ganar evidencia sobre falsos positivos antes de intervenir en operaciones del sistema.

**Evidencia que cambiaría la decisión:** una política operativa explícita, validada en varios hosts, que requiera enforcement automático y tenga un bypass de recuperación seguro y auditable.
