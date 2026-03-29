# Boot Report por Telegram (Ubuntu + systemd timer)

Servicio `oneshot` + `systemd timer` que envía un **reporte diario de salud** a Telegram (por defecto a las **08:30**) con:
- **Backoff/retry** en el envío a Telegram
- **Anti-duplicados diario** (lock + stamp por fecha)
- **Hardening base** en systemd (recomendado)

> El PDF original con el paso a paso está en `docs/Boot.pdf`.

---

## Qué envía
- Red: IP LAN e IP pública (best effort)
- Sistema: hostname, kernel, uptime, fecha/hora
- Métricas: disco `/`, RAM (MemAvailable), load normalizado por CPU, temperatura (opcional)
- Salud: `systemctl --failed`
- Operación: updates pendientes (best effort)

---

## Requisitos
- Linux con `systemd`
- `curl`, `iproute2`, `util-linux` (flock), `coreutils`
- (Opcional) `lm-sensors` para temperatura (`sensors`)

---

## Instalación rápida

```bash
git clone <este-repo>
cd boot-report
sudo ./scripts/install.sh
sudo nano /opt/boot-report/.env
sudo systemctl start boot-report.service
journalctl -u boot-report.service --no-pager -n 120
```

> Importante: el script instala y habilita el **timer**. El `start` del service es solo para probar manualmente.

---

## Configuración (`/opt/boot-report/.env`)

El instalador copia `.env.example` a `/opt/boot-report/.env` si no existe.
Campos obligatorios:

- `BOT_TOKEN`
- `CHAT_ID`

Opcionales útiles:

- `SERVER_LABEL` (nombre amigable del server)
- `BOOT_ALERTS_ONLY=true` (solo envía si hay WARN/CRIT)
- `BOOT_EMOJI=true` (íconos por severidad)

Umbrales (en porcentaje o °C):

- `WARN_LOAD_PCT`, `CRIT_LOAD_PCT`
- `WARN_RAM_PCT`, `CRIT_RAM_PCT`
- `WARN_DISK_PCT`, `CRIT_DISK_PCT`
- `WARN_TEMP_C`, `CRIT_TEMP_C`

---


## Evidencia persistente

Cada corrida deja artefactos en `/var/lib/boot-report/reports/<RUN_ID>/`:

- `report.json` con señales, severidades, fases y message ids
- `summary.txt` con el resumen principal enviado
- symlink `latest/` a la última corrida

Esto permite revisar historial sin depender solo de Telegram.

## Política de notificación

`BOOT_NOTIFY_POLICY` controla cuándo enviar Telegram:

- `always`: siempre envía resumen
- `issues`: solo envía si hay WARN/CRIT
- `never`: genera reportes locales sin enviar

## Programación (08:30 diario)

Se ejecuta todos los días a las **08:30** en el timezone del servidor.

Ver próxima ejecución:

```bash
systemctl list-timers --all | grep boot-report
```

Forzar ejecución manual:

```bash
sudo systemctl start boot-report.service
```

Si no envía nada y en logs aparece `SKIP: ya se ejecutó hoy`, es el anti‑duplicado diario.
Para forzar un envío de prueba:

```bash
sudo rm -f /var/lib/boot-report/last_run_date
sudo systemctl start boot-report.service
```


---

## Timezone

El `OnCalendar` usa el timezone del sistema. Ver:

```bash
timedatectl | grep "Time zone"
```

Si necesitás cambiarlo:

```bash
sudo timedatectl set-timezone America/Chicago
```

---

## Troubleshooting

Ver logs del service:

```bash
journalctl -u boot-report.service --no-pager -n 200
```

Ver logs del timer:

```bash
journalctl -u boot-report.timer --no-pager -n 200
```

Probar conectividad:
- DNS: `getent hosts api.telegram.org`
- Ruta: `ip route get 1.1.1.1`

Si Telegram responde OK pero no llega nada, revisar `CHAT_ID` y permisos del bot (grupos/canales).

---

## Modificar

> Nota (zsh): si tu shell es zsh, el glob `*.sh` puede fallar con `no matches found`.
> En ese caso usá los `find` de abajo.

Usamos 
sudo tee /opt/boot-report/lib/system.sh >/dev/null <<'EOF'
** Archivo
EOF

sudo chown bootreport:bootreport /opt/boot-report/boot-report.sh
sudo chmod 0750 /opt/boot-report/boot-report.sh

sudo find /opt/boot-report/lib -maxdepth 1 -type f -name "*.sh" -exec chown bootreport:bootreport {} \;
sudo find /opt/boot-report/lib -maxdepth 1 -type f -name "*.sh" -exec chmod 0640 {} \;

sudo systemctl restart boot-report.service
sudo journalctl -u boot-report.service -n 120 --no-pager

## Desinstalar
```bash
sudo ./scripts/uninstall.sh
```

---

## Estructura

```
.
├─ boot-report.sh
├─ .env.example
├─ systemd/
│  ├─ boot-report.service
│  └─ boot-report.timer
├─ scripts/
│  ├─ install.sh
│  └─ uninstall.sh
└─ docs/Boot.pdf
```
