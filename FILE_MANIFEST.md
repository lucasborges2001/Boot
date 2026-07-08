# FILE_MANIFEST — Boot

## Server package

Rutas esperadas cuando existen en el checkout:

```txt
bin/
lib/
config/
scripts/server/
systemd/
README-INSTALL.md
README.md
FILE_MANIFEST.md
DELETE_MANIFEST.md
boot-report.sh
```

Archivo mínimo obligatorio:

```txt
bin/boot-report
```

## Web package

Rutas esperadas cuando existen en el checkout:

```txt
back/
config/
database/
public_html/
docs/
README.md
FILE_MANIFEST.md
DELETE_MANIFEST.md
```

Archivo mínimo obligatorio:

```txt
public_html/api/health.php
```

## Regla

Los scripts de packaging deben incluir rutas opcionales solo si existen. No deben fallar por manifests, `database/` u otros directorios ausentes.
