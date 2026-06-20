# Instalación Boot

## Dependencia Base

Boot resuelve `Base` en este orden:

1. `BASE_DIR=/opt/base`
2. layout local `Pruebas/submodules/Base` junto a `Pruebas/submodules/Boot`
3. fallback relativo `../Base`
4. `/opt/base`

En Bash carga:

```bash
source "$BASE_DIR/lib/shell/env.sh"
source "$BASE_DIR/lib/shell/log.sh"
source "$BASE_DIR/lib/shell/json.sh"
source "$BASE_DIR/lib/shell/lock.sh"
source "$BASE_DIR/lib/shell/time.sh"
source "$BASE_DIR/lib/shell/telegram.sh"
```

En PHP, `back/bootstrap.php` intenta cargar `Base/back/bootstrap.php` y `base_bootstrap_load_core()`. Si el paquete de Base no trae bootstrap, carga directamente las clases Base requeridas para smoke/local.

## Servidor

```bash
cd Boot
sudo BASE_DIR=/opt/base bash scripts/server/install.sh
sudo nano /opt/boot-report/config/server.env
sudo systemctl restart boot-report.timer
```

El instalador no crea secretos. Configurar `TELEGRAM_BOT_TOKEN` y `TELEGRAM_CHAT_ID` manualmente.

## Web/SuperAdmin

Publicar estos directorios en el entorno web:

```txt
back/
config/
database/
public_html/
docs/
```

La UI no ejecuta comandos del sistema. Solo lee snapshots ya generados.

## Paquetes

```bash
bin/boot-report-package
```

Genera:

- `dist/boot-server.tar.gz`
- `dist/boot-web.tar.gz`

## Validación

```bash
find . -name '*.php' -print0 | xargs -0 -n1 php -l
bash scripts/dev/smoke.sh
```

Requisitos para smoke: `bash`, `php`, `python3`; `systemctl`, `sensors`, `apt/dnf/yum/pacman` son opcionales y degradan con valores neutros.
