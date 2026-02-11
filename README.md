# Boot Report por Telegram (Ubuntu + systemd)

Servicio `oneshot` que envía un **reporte de salud post-boot** a Telegram con anti-duplicados (lock + stamp), backoff/retry y hardening base de systemd.

Incluye:
- Métricas rápidas: disco, memoria, load por core, temperatura (opcional), uptime
- Operación: updates pendientes (best effort), flag de `reboot-required`
- Red: IP LAN, gateway, IP pública (best effort)
- Anti-duplicados: evita re-envíos dentro de una ventana por `boot_id`

> El PDF completo con el paso a paso está en `docs/Boot.pdf`.

## Requisitos
- Ubuntu (o distro compatible) + systemd
- `curl`, `iproute2`, `util-linux` (flock), `coreutils`
- (Opcional) `lm-sensors` para temperatura

## Instalación rápida

```bash
git clone <este-repo>
cd boot-report
sudo ./scripts/install.sh
sudo nano /opt/boot-report/.env
sudo systemctl start boot-report.service
journalctl -u boot-report.service -b --no-pager
```

El servicio queda habilitado para correr en cada boot:

```bash
sudo systemctl enable boot-report.service
```

## Configuración (`/opt/boot-report/.env`)
Copiá desde `.env.example`. Campos obligatorios:

- `BOT_TOKEN`
- `CHAT_ID`

Opcionales importantes:

- `SERVER_LABEL`
- `BOOT_ALERTS_ONLY=true` (solo envía si hay WARN/CRIT)
- `LOCK_TTL_SEC=900` (anti-duplicados)

## Troubleshooting

- Ver logs:
  ```bash
  journalctl -u boot-report.service -b --no-pager
  ```
- Probar conectividad:
  - DNS: `getent hosts api.telegram.org`
  - Ruta: `ip route get 1.1.1.1`
- Si Telegram responde 200 pero no llega nada, revisá `CHAT_ID` y permisos del bot (grupos/canales).

## Desinstalar
```bash
sudo ./scripts/uninstall.sh
```

## Estructura

```
.
├─ boot-report.sh
├─ .env.example
├─ systemd/boot-report.service
├─ scripts/install.sh
├─ scripts/uninstall.sh
└─ docs/Boot.pdf
```
