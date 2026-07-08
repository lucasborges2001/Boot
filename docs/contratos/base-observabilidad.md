# Contrato con Base

## Propósito

`Boot` consume `Base` para helpers y contratos compartidos. No debe duplicar lógica genérica que ya pertenezca a `Base`.

## Resolución esperada

La resolución compatible debe contemplar:

1. `BASE_DIR` explícito;
2. checkout vecino `../Base`;
3. layout de submódulos dentro de `Pruebas`;
4. `/opt/base` en instalación productiva.

## Criterio de fallo

Si `Base` no puede resolverse en un contexto donde es obligatorio, Boot debe fallar explícitamente con error legible. En tests seguros, debe poder usar layout local sin tocar producción.

## Límites

- No asumir `/opt/base` en desarrollo.
- No instalar Base desde Boot.
- No modificar Base desde Boot.
- No convertir Boot en dependencia obligatoria del host.
