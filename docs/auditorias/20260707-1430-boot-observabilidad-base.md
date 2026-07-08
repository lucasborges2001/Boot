# Auditoría Boot — observabilidad dependiente de Base

## Alcance

Auditoría de `lucasborges2001/Boot` como submódulo de `Pruebas/submodules/Boot`.

Objetivo: actualizar `Boot/docs` con documentación operativa, contratos y pendientes priorizados siguiendo el estilo de `Pruebas/docs`.

## Fuentes revisadas

| Fuente | Resultado |
|---|---|
| `Pruebas/.gitmodules` | `Boot` apunta a `https://github.com/lucasborges2001/Boot.git`, branch `main`. |
| `Pruebas/config/submodules.php` | `Boot` es `tooling-server-bootstrap`, opcional, no bloqueante, fuera de app deploy. |
| `Boot/README.md` | Define Boot como observabilidad del servidor dependiente de Base. |
| `Boot/README-INSTALL.md` | Documenta resolución de Base, instalación server, publicación web, paquetes y validación. |
| `Boot/bin/boot-report` | CLI principal. |
| `Boot/lib/shell/*` | Colecta, render y persistencia shell. |
| `Boot/back/*` | Bootstrap, normalización y servicios PHP. |
| `Boot/public_html/api/*` | API read-only. |
| `Boot/public_html/superadmin/*` | UI read-only. |
| `Boot/test/*` | Smokes shell/PHP y test CLI disposable. |

## Hechos verificados

- Boot no es módulo runtime obligatorio del host.
- Boot depende de Base para helpers shell y contratos PHP comunes.
- El CLI admite `--env`, `--reports-dir`, `--no-telegram` y `--print`.
- La persistencia escribe `latest/report.json`, `latest/summary.txt` y snapshot histórico.
- El timer auditado corre al boot y luego cada 15 minutos.
- La API expone `health`, `latest` e `history`.
- La UI SuperAdmin lee snapshots y no aparece como ejecutora de comandos del sistema en los archivos revisados.
- Existe fixture `var/sample-reports/latest/report.json` con `module=boot` y `schema_version=1`.

## Diagnóstico

`Boot` está razonablemente encaminado: separa bien runtime shell, normalización PHP, API y UI. La frontera con Base está explícita y evita duplicar helpers genéricos.

La deuda principal ya no es conceptual sino de cierre operativo:

1. packaging debe verificarse/corregirse porque los scripts referencian manifests no confirmados;
2. SuperAdmin debería alinearse con componentes Base o declarar excepción visual;
3. falta una suite host opcional para validar Boot desde `Pruebas` sin convertirlo en preflight bloqueante;
4. falta validación productiva con systemd y Telegram real en entorno controlado.

## Riesgos

| Prioridad | Riesgo | Impacto |
|---|---|---|
| P0 | Packaging con manifests faltantes | No se pueden generar tarballs reproducibles. |
| P0 | Base no instalado o desalineado en producción | Boot no arranca o falla bootstrap. |
| P1 | UI fuera de patrón Base | Inconsistencia de SuperAdmin y duplicación CSS. |
| P1 | API sin smoke web dedicado | Regresiones no detectadas en rutas públicas. |
| P2 | Telegram validado solo como contrato | Falla silenciosa por credenciales/permisos. |

## Pendientes generados

| Archivo | Prioridad | Tema |
|---|---|---|
| `pendientes/20260707-1430-boot-packaging-manifests.md` | P0 | Corregir/confirmar manifests de packaging. |
| `pendientes/20260707-1440-boot-superadmin-base-ui.md` | P1 | Alinear UI con Base o documentar excepción. |
| `pendientes/20260707-1450-boot-host-testkit.md` | P1 | Suite host opcional no bloqueante. |
| `pendientes/20260707-1500-boot-operacion-productiva.md` | P0 | Validación productiva systemd + Telegram. |

## Verificación sugerida

```bash
cd submodules/Boot
bash scripts/dev/smoke.sh
bin/boot-report-test
BOOT_REPORTS_DIR=/tmp/boot-report/reports BOOT_SEND_TELEGRAM=false bin/boot-report --no-telegram --print | python3 -m json.tool
bin/boot-report-package
```

Desde `Pruebas`:

```bash
php submodules/Base/bin/base-host-submodules-contract \
  --root . \
  --gitmodules .gitmodules \
  --manifest config/submodules.php \
  --mode check
```

## Criterio de cierre

La fase queda cerrada cuando:

- `docs/` nuevo reemplaza documentación previa;
- el packaging se ejecuta sin error;
- existe smoke web/API;
- Boot tiene validación productiva documentada;
- los pendientes se cierran o promueven a cambios.
