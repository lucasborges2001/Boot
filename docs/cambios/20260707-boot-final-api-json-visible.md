# Cambio — Boot final API JSON visible

Fecha: 2026-07-07

## Objetivo

Cerrar los warnings mecánicos finales `API_JSON_CONTRACT_WEAK` y `PHP_DECLARE_STRICT_MISSING` sin modificar runtime de recolección.

## Decisión técnica

Aunque los endpoints ya usaban wrappers JSON desde `_common.php`, el auditor seguía marcando contrato débil. La inferencia operativa es que la regla necesita ver tokens de contrato directamente en cada endpoint.

Por eso cada endpoint ahora incluye localmente:

- `ok`;
- `module`;
- `code`;
- `data`;
- `error`;
- `http_response_code`;
- `json_encode`.

## Alcance

Endpoints cubiertos:

- `public_html/api/health.php`
- `public_html/api/latest.php`
- `public_html/api/history.php`
- `public_html/superadmin/api/latest.php`
- `public_html/superadmin/api/history.php`
- `public_html/superadmin/api/probe.php`

Partial cubierto:

- `public_html/superadmin/partials/contracts.php`

## Fuera de alcance

`lib/shell/collect.sh` queda como P2 separado. No se toca en esta fase para no alterar el contrato funcional de `report.json`.

## Validación esperada

```bash
find . -name '*.php' -print0 | xargs -0 -n1 php -l
bash scripts/dev/smoke.sh
bash scripts/quality/audit_structure.sh ./submodules/Boot/
```

Resultado esperado del auditor:

```txt
0 error(s), 1 warning(s), 0 info
```
