# Contrato de snapshot Boot

Boot genera JSON con `module=boot`, `schema_version=1`, `generated_at`, `server`, `status`, `metrics`, `updates`, `services`, `telegram` y `artifacts`.

El archivo canónico es:

```txt
/var/lib/boot-report/reports/latest/report.json
```

`back/metrics/BootReportNormalizer.php` lo transforma a `MetricSnapshot` de Base y a un shape estable para API/UI.
