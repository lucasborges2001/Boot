# Boot: despliegue compartido en ~/servidor/

Estado: **preparación de integración**, sin instalación ni cutover autorizado. El
instalador legacy scripts/server/install.sh sigue apuntando a /opt y bloquea
expresamente la sustitución accidental del servicio antiguo.

## Objetivo y ownership

La raíz física para esta modalidad es /home/<account>/servidor (sin symlinks en
el directorio raíz ni sus ancestros). Boot es owner de la recolección host y su
unidad systemd; Base es owner de sus helpers shell. Riegos solo consume un
snapshot sanitizado por un publicador independiente, con montaje read-only.

Rutas objetivo:

- releases/base/<SHA>/, current/base -> release validado;
- releases/boot/<SHA>/, current/boot -> release validado;
- config/boot/server.env (secreto local, no versionado);
- state/boot/reports/{latest,<timestamp>}/ (privado);
- systemd/boot-report.{service,timer} (artefactos de staging);
- reports/boot/ (publicación sanitizada, todavía no implementada);
- manifests/ y packages/ para evidencia y procedencia.

Las unidades efectivas, cuando se autorice el cutover, deben registrarse en
/etc/systemd/system: ese registro no es el directorio de instalación del módulo.

## Generación read-only de unidades

Desde el checkout de Boot, sustituir la cuenta por la real:

```bash
python3 -B scripts/server/render-servidor-units.py \
  --root /home/tecnicosfivisa/servidor --unit boot-report.service
python3 -B scripts/server/render-servidor-units.py \
  --root /home/tecnicosfivisa/servidor --unit boot-report.timer
bash test/shell/boot_servidor_units_test.sh
```

El renderizador solo escribe en stdout. No crea carpetas, no llama a systemctl,
no lee secretos y no genera un instalador ejecutable. La ruta impresa debe
revisarse antes de almacenar las unidades en servidor/systemd/.

## Gates previos a cualquier activación

1. Resolver SHA exactos de Base y Boot; verificar los binarios bajo
   current/base y current/boot (sin depender de /opt/base).
2. Asegurar que config/boot/server.env especifique BOOT_REPORTS_DIR dentro de
   state/boot/reports; verificar directorio, modo, propietario, ausencia de
   symlinks y acceso efectivo como bootreport.
3. ProtectHome=read-only permite *lectura* de /home, no ignora DAC/ACL:
   verificar los permisos de travesía para bootreport sin abrir todo HOME.
   ReadWritePaths restringe escrituras al estado del módulo.
4. Validar con systemd-analyze verify y una ejecución de muestra controlada
   sin Telegram, después de aprobar expresamente esa operación.
5. Respaldar unidad, scripts y config legacy; evitar timers simultáneos y
   alertas duplicadas; comprobar snapshot v2 y frescura con el doctor.
6. Documentar rollback antes de cambiar /etc/systemd/system. No borrar
   /opt/boot-report ni /var/lib/boot-report durante la preparación.

**Riesgo pendiente:** la unidad actual del repositorio usa root en /opt;
la alternativa servidor conserva bootreport, pero su capacidad de observar
todas las métricas debe comprobarse. No subir privilegios sin evidencia.
