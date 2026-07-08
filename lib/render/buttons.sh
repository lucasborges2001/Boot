#!/usr/bin/env bash
# Botones inline legacy para Telegram Boot.

render_buttons_json() {
  local temps_url="$1" updates_url="$2" failed_url="$3" howto_url="$4"

  cat <<JSON
{"inline_keyboard":[
  [{"text":"🌡 Temperaturas","url":"${temps_url}"},{"text":"📦 Actualizaciones","url":"${updates_url}"}],
  [{"text":"🧩 Servicios","url":"${failed_url}"},{"text":"🛠️ Actualizar","url":"${howto_url}"}]
]}
JSON
}
