# Arquitectura Boot

Boot queda dividido en capas:

- `bin/`: entrypoints CLI.
- `lib/shell/`: recolección, render y persistencia específicos del servidor.
- `back/`: lectura, normalización y servicios PHP.
- `public_html/api`: endpoints JSON read-only.
- `public_html/superadmin`: pantalla operativa sin DB.
- `scripts/server` y `scripts/web`: empaquetado e instalación.

La capa genérica queda en Base. Boot no debe reimplementar cliente Telegram, parseo de JSON, helpers de env, locks ni contratos genéricos de métricas.
