# Contrato de packaging

## Paquetes esperados

```txt
dist/boot-server.tar.gz
dist/boot-web.tar.gz
```

## Comando

```bash
bash bin/boot-report-package
```

## Estado actual

Validado en checkout real. Se reportó generación exitosa de ambos tarballs.

## Reglas

- Packaging no debe depender de secretos reales.
- Rutas opcionales inexistentes no deben romper el tar.
- Manifests deben existir y describir el contenido esperado.
- El smoke debe fallar si el empaquetado deja de generar ambos tarballs.

## Verificación

```bash
bash bin/boot-report-package
tar -tzf dist/boot-server.tar.gz | head
tar -tzf dist/boot-web.tar.gz | head
```
