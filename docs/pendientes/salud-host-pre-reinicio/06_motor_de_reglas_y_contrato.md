# Fase 06 — Motor de reglas y contrato

## Estado

Pendiente.

## Objetivo

Separar recolección de datos y decisión operativa para que las reglas sean testeables, explicables y extensibles.

## Principio

Los colectores describen hechos. El motor de reglas produce conclusiones.

```text
collector output
→ normalized facts
→ rule evaluation
→ findings
→ global decision
```

No se deben ocultar fallos de recolección dentro de valores por defecto saludables.

## Severidades propuestas

```text
OK        sin anomalías relevantes
INFO      información operativa
WARNING   riesgo no inmediato
ERROR     componente degradado
CRITICAL  fallo activo que requiere intervención
BLOCK     operación insegura, por ejemplo reiniciar
UNKNOWN   no pudo comprobarse
```

`BLOCK` no implica necesariamente que el host esté caído. Indica que una operación concreta no es segura.

## Contrato propuesto

Extensión aditiva pendiente de decidir versión de schema:

```json
{
  "health": {
    "overall": "error",
    "safe_to_reboot": false,
    "safe_to_update": false,
    "checks_total": 0,
    "findings": [
      {
        "id": "kernel.target_package_incomplete",
        "severity": "block",
        "operation": "reboot",
        "summary": "El kernel objetivo no está configurado completamente",
        "evidence": {
          "kernel": "7.0.0-28-generic",
          "packages": []
        },
        "remediation": {
          "automatic": false,
          "reference": "docs/operacion/..."
        }
      }
    ]
  }
}
```

## Requisitos del contrato

- IDs de regla estables;
- evidencia estructurada;
- resumen humano breve;
- operación afectada;
- timestamps y fuente;
- `available`/`unknown` explícitos;
- sin rutas absolutas expuestas por API;
- sin logs completos o secretos;
- compatibilidad de readers anteriores;
- orden determinista para tests y diffs.

## Operaciones evaluables

Primera fase:

- `reboot`;
- `update`;
- `continue_operation`.

No se deben agregar operaciones de reparación automática.

## Reglas compuestas mínimas

### Kernel incompleto

```text
kernel objetivo detectado
+ paquete kernel incompleto
= BLOCK reboot
```

### DKMS bloqueante

```text
kernel objetivo
+ DKMS fallido para ese kernel
+ módulo requerido o transacción dpkg incompleta
= BLOCK reboot
```

### Sin fallback

```text
kernel objetivo no validado
+ no existe kernel anterior consistente
= BLOCK reboot
```

### Reboot requerido normal

```text
reboot-required
+ dpkg consistente
+ kernel objetivo consistente
+ initramfs presente
+ fallback válido
= WARNING, safe_to_reboot=true
```

## Exit codes propuestos

Para una CLI específica:

```text
0 = saludable para la operación solicitada
1 = advertencias
2 = errores o críticos
3 = operación bloqueada
4 = chequeo incompleto/unknown relevante
```

El contrato definitivo debe evitar incompatibilidades con los códigos actuales de `boot-report`.

## Configuración

Pendientes:

- [ ] allowlist de módulos requeridos;
- [ ] clasificación de servicios críticos;
- [ ] umbrales de storage, memoria y temperatura;
- [ ] ventana temporal de logs;
- [ ] suppressions auditables con motivo y vencimiento;
- [ ] política sobre `unknown` para cada operación;
- [ ] perfiles `default`, `pre-reboot` y `deep`;
- [ ] defaults seguros sin datos específicos del host.

## Implementación propuesta

- colectores shell pequeños y aislados;
- normalización y reglas en Python;
- fixtures JSON/texto para tests;
- renderers existentes consumen el resultado normalizado;
- Base sólo aporta helpers genéricos.

## Criterios de aceptación

- la misma evidencia produce siempre la misma decisión;
- una regla puede probarse sin ejecutar comandos reales;
- `unknown` nunca se convierte implícitamente en `ok`;
- un hallazgo incluye fuente y evidencia verificable;
- `safe_to_reboot=false` puede explicarse por al menos un finding `BLOCK`;
- readers v1/v2 continúan funcionando.

## Criterio de cierre

La fase termina cuando el contrato, severidades, exit codes y reglas compuestas están documentados y cubiertos por tests unitarios con fixtures.

## Revisión de evidencia — 2026-11-02

**Clasificación: abierto; contrato propuesto, no implementado ni validado.** El árbol de `main` contiene `lib/python/build_report.py`, tests de telemetría y contratos JSON v1/v2; no se identifican tests dedicados al motor de reglas de pre-reinicio ni una CLI `boot-health`.

**Reutilización:** revisar normalización y readers actuales antes de introducir un nuevo esquema. Los umbrales de telemetría no equivalen a reglas de bloqueo de reboot.

**Decisiones pendientes:** semántica de `unknown` por operación; precedencia de severidades; estabilidad de IDs; exit codes; política de compatibilidad; reglas DKMS/kernel y evidencia saneada.

**Pruebas exigidas:** fixtures de kernel sano, paquetes incompletos, DKMS fallido, fallback ausente, colector sin permisos y resultado desconocido. Comparar decisiones deterministas y preservar readers v1/v2.

**PASS:** reglas y contratos versionados con tests de casos positivos/negativos. **No verificado:** ejecución de suites, integración real y permisos en host.
