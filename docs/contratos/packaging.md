# Contrato de packaging

## Objetivo

Generar paquetes separados para instalación server y publicación web.

## Comando

```bash
bin/boot-report-package
```

## Paquetes esperados

| Paquete | Script | Contenido esperado |
|---|---|---|
| `dist/boot-server.tar.gz` | `scripts/server/package-server.sh` | `bin`, `lib`, `config`, `scripts/server`, `systemd`, documentación mínima y wrapper. |
| `dist/boot-web.tar.gz` | `scripts/web/package-web.sh` | `back`, `config`, `database`, `public_html`, `docs`, documentación y manifest. |

## Brecha detectada

Los scripts de package referencian:

```txt
FILE_MANIFEST.md
DELETE_MANIFEST.md
```

En esta auditoría esos archivos no fueron verificados como existentes. Si faltan en el checkout real, `tar` puede fallar y bloquear la generación de paquetes.

## Decisión pendiente

Elegir una de estas rutas:

1. crear `FILE_MANIFEST.md` y `DELETE_MANIFEST.md` como contratos vivos;
2. removerlos de los scripts si ya no se usan;
3. reemplazarlos por documentación dentro de `docs/contratos/` y ajustar packaging.

## Validación requerida

```bash
cd submodules/Boot
bin/boot-report-package
ls -lh dist/boot-server.tar.gz dist/boot-web.tar.gz
tar -tzf dist/boot-server.tar.gz >/tmp/boot-server.files
tar -tzf dist/boot-web.tar.gz >/tmp/boot-web.files
```

## Criterio de cierre

- El comando termina con exit code `0`.
- Ambos tarballs existen.
- El paquete server contiene `bin/boot-report`, `systemd/boot-report.service`, `systemd/boot-report.timer` y `config/server.env.example`.
- El paquete web contiene `back/bootstrap.php`, `public_html/api/latest.php`, `public_html/superadmin/index.php` y `docs/README.md`.
