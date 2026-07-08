# Boot SuperAdmin Front

## Propósito

La pantalla `public_html/superadmin/index.php` muestra el estado read-only del último snapshot generado por `bin/boot-report`.

No ejecuta comandos del sistema. No dispara recolecciones. No envía Telegram. No modifica archivos de `/var/lib/boot-report`.

## Estructura

| Archivo | Responsabilidad |
|---|---|
| `index.php` | Orquestador HTML de la pantalla. |
| `_pageBootstrap.php` | Carga Bootstrap PHP, servicios y datos read-only. |
| `support/helpers.php` | Escape HTML y formato de porcentajes. |
| `partials/hero.php` | Identidad de pantalla y severidad general. |
| `partials/status.php` | Estado general y datos básicos del servidor. |
| `partials/metrics.php` | Métricas principales de recursos, updates y servicios. |
| `partials/telegram.php` | Estado reportado de Telegram sin secretos. |
| `partials/history.php` | Historial reciente. |
| `partials/contracts.php` | Rutas contractuales y schema. |
| `assets/boot-superadmin.js` | Hook JS read-only mínimo. |

## Endpoints usados

La pantalla puede consumir, si se extiende por JS, estos endpoints read-only:

```txt
public_html/superadmin/api/probe.php
public_html/superadmin/api/latest.php
public_html/superadmin/api/history.php
```

Todos aceptan solo `GET` y devuelven JSON con:

```json
{
  "ok": true,
  "module": "boot",
  "code": "boot.probe.ok",
  "data": {}
}
```

## Relación con Base UI

La vista actual es una pantalla propia minimalista. Consume contratos PHP de Boot y Base, pero no está completamente migrada a componentes Base UI.

Criterio para migrar en una fase futura:

- mantener read-only;
- no agregar formularios de acción;
- conservar los endpoints estables;
- reemplazar tarjetas/tablas propias por componentes Base solo si mejora consistencia sin aumentar acoplamiento.

## Restricciones

No agregar en esta pantalla:

- botones para ejecutar `bin/boot-report`;
- controles para reiniciar servicios;
- acciones de update/upgrade;
- edición de `.env`;
- envío manual de Telegram;
- escritura directa en `/var/lib/boot-report`.
