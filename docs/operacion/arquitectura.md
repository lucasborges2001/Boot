# Arquitectura operativa

## Flujo principal

```txt
bin/boot-report
  -> resuelve Base
  -> lib/shell/collect.sh
  -> lib/shell/render.sh
  -> lib/shell/persist.sh
  -> report.json / summary.txt
  -> Telegram opcional
```

## Capa PHP

```txt
back/bootstrap.php
back/support/base-resolver.php
back/support/config.php
back/support/paths.php
back/support/contracts.php
back/metrics/*
```

La capa PHP lee snapshots y los normaliza. No ejecuta recolección.

## Capa web

```txt
public_html/api/*
public_html/superadmin/*
```

La capa web es read-only y se apoya en snapshots existentes.

## Separación de responsabilidades

| Capa | Puede hacer | No debe hacer |
|---|---|---|
| CLI | Colectar, persistir, enviar Telegram opcional. | Exponer secretos o depender de web. |
| PHP back | Leer/normalizar reportes. | Ejecutar comandos de sistema. |
| API | Responder JSON read-only. | Mutar estado o ejecutar acciones. |
| SuperAdmin | Mostrar estado. | Orquestar operaciones productivas. |
