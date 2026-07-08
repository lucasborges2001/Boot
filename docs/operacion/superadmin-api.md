# SuperAdmin y API read-only

## Contrato

La capa web de `Boot` debe ser read-only. Lee snapshots ya generados y no ejecuta comandos del sistema.

## Endpoints

| Endpoint | Método esperado | Respuesta |
|---|---:|---|
| `public_html/api/health.php` | `GET` | Estado resumido: `ok`, `module`, `severity`, `summary`, `generated_at`, `latest_path`. |
| `public_html/api/latest.php` | `GET` | Último snapshot normalizado o `404` si no hay snapshot. |
| `public_html/api/history.php?limit=10` | `GET` | Lista de snapshots recientes con límite entre `1` y `50`. |

## SuperAdmin

Entrada:

```txt
public_html/superadmin/index.php
```

La pantalla carga:

```txt
_pageBootstrap.php
partials/hero.php
partials/status.php
partials/metrics.php
partials/telegram.php
partials/history.php
partials/contracts.php
assets/boot-superadmin.js
boot-superadmin.css
```

## Estado visual

La UI actual usa CSS propio con paleta oscura, cards y badges. Es funcional, pero conviene evaluar migración a componentes `Base` si se busca consistencia con el resto del SuperAdmin del host.

## Pruebas manuales sugeridas

```bash
php -S 127.0.0.1:8099 -t public_html
curl -s http://127.0.0.1:8099/api/health.php | python3 -m json.tool
curl -s http://127.0.0.1:8099/api/latest.php | python3 -m json.tool
curl -s 'http://127.0.0.1:8099/api/history.php?limit=5' | python3 -m json.tool
```

## Condiciones a validar

| Caso | Resultado esperado |
|---|---|
| No existe snapshot real, pero existe sample | UI/API pueden mostrar sample para smoke/local. |
| No existe snapshot ni sample | `latest.php` responde `404` con error controlado. |
| `limit` inválido en history | Se normaliza al rango `1..50`. |
| Snapshot corrupto | Health debe reportar `ok=false` o error de lectura, no HTML roto. |

## Pendiente de endurecimiento

Agregar smokes específicos para asegurar que la capa web no contenga formularios, botones de ejecución ni llamadas a `shell_exec`, `exec`, `system`, `passthru` o equivalentes.
