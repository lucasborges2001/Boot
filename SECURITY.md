# Security

- **No commitees** `.env` (contiene `BOT_TOKEN`).
- El servicio corre como usuario no-root (`bootreport`) y con hardening de systemd.
- Recomendación: crea un bot dedicado para infra, no reutilices tokens de otros entornos.
