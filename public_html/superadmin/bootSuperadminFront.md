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

## Relación con Base UI — decisión arquitectónica (2026-11-02)

**Decisión: excepción documentada.** SuperAdmin de Boot conserva por ahora una vista PHP/CSS propia, minimalista y read-only. No se realizará una migración preventiva a Base UI sin un consumidor integrado y una mejora demostrable.

### Evidencia y fundamento

- En Boot, `public_html/superadmin/index.php` compone parciales y carga `boot-superadmin.css`; `_pageBootstrap.php` prepara el view model propio, y los endpoints permanecen read-only.
- Base publica componentes reutilizables, entre ellos `base_component_card()` y `base_component_metric()` bajo su contrato `public_html/components`. **La decisión no se basa en ausencia de componentes.**
- `scripts/web/package-web.sh` empaqueta `back`, `config`, `public_html` y documentación de Boot; no incluye assets frontend de Base. Cambiar a sus componentes exigiría resolver y validar un contrato de distribución/URLs de assets en todos los despliegues.
- `back/support/base-resolver.php` utiliza helpers PHP de Base cuando está disponible; esto no convierte los assets del frontend en dependencia cubierta por packaging.
- Duplicar visuales de manera acotada es una deuda de estilo aceptada; **no** se autoriza duplicar reglas de dominio, parsers, contratos JSON ni lógica de observabilidad.

### Invariantes de la excepción

- Mantener read-only: ninguna ejecución de comandos, envío de Telegram, mutación de estado, formularios operativos ni cambios de configuración desde web.
- Reutilizar contratos públicos y normalizadores existentes en lugar de copiar lógica de Base.
- Limitar el CSS local a presentación de Boot; no crear una librería reusable paralela.
- Conservar compatibilidad de endpoints, escaping HTML y sanitización de paths.
- Registrar cualquier ampliación funcional de la UI como decisión separada, con test de seguridad y packaging.

### Cuándo reconsiderar la migración

Reabrir esta decisión si el host consumidor provee Base UI como contrato público estable para el paquete web, si aparecen varias pantallas duplicando componentes genéricos o si se exige un diseño transversal uniforme. Antes de migrar, verificar entrypoints públicos, URLs/assets, compatibilidad de tema, packaging y smokes. No importar internals de Base ni copiar código entre módulos.

### Validación y reversión

Esta es **una decisión documental**, no una certificación de funcionamiento. Se verificaron fuentes y contratos estáticamente en `main` de Boot y Base; no se ejecutaron smokes, CI ni pruebas visuales. El rollback es revertir este cambio documental y reabrir la decisión.

## Restricciones

No agregar en esta pantalla:

- botones para ejecutar `bin/boot-report`;
- controles para reiniciar servicios;
- acciones de update/upgrade;
- edición de `.env`;
- envío manual de Telegram;
- escritura directa en `/var/lib/boot-report`.


## Hardening post P0/P1

La pantalla usa `public_html/superadmin/_pageBootstrap.php` como frontera de composición de view model. Esa frontera consume soportes específicos:

- `support/config.php`: view model de configuración sin secretos.
- `support/paths.php`: paths y existencia de artefactos read-only.
- `support/health.php`: estado normalizado.
- `support/metrics.php`: summary/latest/history.

Los endpoints SuperAdmin se mantienen read-only y exigen método `GET` de forma explícita para que el auditor pueda detectar el guard de método en cada archivo.
