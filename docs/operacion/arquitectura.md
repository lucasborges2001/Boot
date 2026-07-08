# Arquitectura Boot

## Rol

`Boot` es un submódulo de observabilidad de servidor dependiente de `Base`.

No forma parte del app deploy principal de `Pruebas`. En el manifest del host está clasificado como `tooling-server-bootstrap`, opcional, no bloqueante y sin `required_paths` de preflight.

## Flujo runtime

```txt
systemd timer / ejecución manual
↓
bin/boot-report
↓
resolución de Base
↓
lib/shell/collect.sh
↓
lib/shell/render.sh
↓
lib/shell/persist.sh
↓
reports/latest/report.json + summary.txt
↓
API read-only / SuperAdmin / Telegram opcional
```

## Componentes verificados

| Componente | Responsabilidad |
|---|---|
| `bin/boot-report` | Orquestador CLI. Carga Base, recolecta, renderiza, persiste y opcionalmente envía Telegram. |
| `lib/shell/collect.sh` | Recolecta hostname, kernel, uptime, load, RAM, disco, temperatura, updates, reboot y servicios fallidos. |
| `lib/shell/render.sh` | Genera HTML Telegram y resumen texto. |
| `lib/shell/persist.sh` | Persiste `report.json`, `summary.txt`, snapshot histórico y poda por retención. |
| `back/bootstrap.php` | Bootstrap PHP con fallback controlado para clases Base. |
| `back/metrics/*` | Lectura, normalización, health, summary e historial. |
| `public_html/api/*` | Endpoints read-only. |
| `public_html/superadmin/*` | UI read-only para inspección. |

## Límites

Boot no debe:

- aplicar updates del sistema;
- reiniciar servicios;
- borrar reportes salvo retención configurada;
- ejecutar scanners;
- guardar secretos en el repo;
- bloquear el deploy de módulos runtime;
- duplicar helpers genéricos que pertenecen a `Base`.

## Severidad

La severidad se deriva de señales simples:

| Condición | Severidad inferida |
|---|---|
| Disco >= 95%, RAM >= 95% o servicios fallidos | `critical` |
| Disco >= 85%, RAM >= 85%, updates de seguridad o reboot requerido | `warning` |
| Updates pendientes no críticos | `info` |
| Sin señales relevantes | `ok` |

## Riesgos actuales

| Riesgo | Impacto | Acción sugerida |
|---|---|---|
| Packaging referencia manifests no verificados | `boot-server.tar.gz` / `boot-web.tar.gz` pueden fallar. | Crear o remover `FILE_MANIFEST.md` y `DELETE_MANIFEST.md`. |
| SuperAdmin usa CSS/UI propia | Puede quedar fuera del estándar Base visual y contractual. | Migrar a componentes Base o documentar excepción. |
| No hay suite host TestKit declarada | El host no valida Boot como tooling de forma integrada. | Agregar suite opcional no bloqueante. |
| Operación real con Telegram no validada acá | Puede fallar por secretos, DNS o permisos de bot. | Validación manual controlada con `BOOT_SEND_TELEGRAM=true`. |
