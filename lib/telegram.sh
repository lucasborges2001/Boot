#!/usr/bin/env bash
set -euo pipefail

# lib/telegram.sh
# Responsabilidad única: hablar con Telegram (send/edit) y parsear respuestas.

: "${BOT_TOKEN:?Falta BOT_TOKEN (env)}"
: "${CHAT_ID:?Falta CHAT_ID (env)}"

TG_PARSE_MODE="${TG_PARSE_MODE:-HTML}"
TG_DISABLE_WEB_PAGE_PREVIEW="${TG_DISABLE_WEB_PAGE_PREVIEW:-true}"

_tg_retry_curl() {
  local tries=5 delay=1 i
  for i in $(seq 1 "$tries"); do
    if "$@"; then return 0; fi
    sleep "$delay"
    delay=$((delay * 2))
  done
  return 1
}

# Escapado mínimo para HTML de Telegram
# https://core.telegram.org/bots/api#html-style
# Nota: no escapamos comillas porque no las usamos en atributos HTML.
tg_escape_html() {
  local s="${1:-}"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  echo "$s"
}

_tg_check_ok_and_get() {
  # Lee JSON por stdin. Imprime el valor solicitado o sale con error.
  # Uso: echo "$resp" | _tg_check_ok_and_get 'result.message_id'
  local path="$1"
  python3 - "$path" <<PY
import json,sys
p=sys.argv[1]
try:
    d=json.load(sys.stdin)
except Exception as e:
    print(f"INVALID_JSON: {e}", file=sys.stderr)
    sys.exit(2)
if not d.get('ok'):
    print(d, file=sys.stderr)
    sys.exit(1)
cur=d
for part in p.split('.'):
    if isinstance(cur, dict) and part in cur:
        cur=cur[part]
    else:
        print(f"MISSING_PATH: {p}", file=sys.stderr)
        sys.exit(3)
print(cur)
PY
}

_tg_api_post() {
  local method="$1"; shift
  local resp
  resp="$(_tg_retry_curl curl -sS -X POST "https://api.telegram.org/bot${BOT_TOKEN}/${method}" "$@")" || return 1
  echo "$resp"
}

tg_send_message() {
  # stdout: message_id
  # args: text [reply_to_message_id]
  local text="$1"
  local reply_to="${2:-}"

  local args=(
    -d "chat_id=${CHAT_ID}"
    -d "parse_mode=${TG_PARSE_MODE}"
    -d "disable_web_page_preview=${TG_DISABLE_WEB_PAGE_PREVIEW}"
    --data-urlencode "text=${text}"
  )

  if [[ -n "$reply_to" ]]; then
    args+=( -d "reply_to_message_id=${reply_to}" )
  fi

  local resp
  resp="$(_tg_api_post sendMessage "${args[@]}")" || {
    echo "ERROR: Telegram sendMessage failed" >&2
    return 1
  }

  echo "$resp" | _tg_check_ok_and_get 'result.message_id'
}

tg_edit_reply_markup() {
  # args: message_id reply_markup_json
  local message_id="$1"
  local reply_markup="$2"

  local resp
  resp="$(_tg_api_post editMessageReplyMarkup \
    -d "chat_id=${CHAT_ID}" \
    -d "message_id=${message_id}" \
    --data-urlencode "reply_markup=${reply_markup}")" || {
    echo "ERROR: Telegram editMessageReplyMarkup failed" >&2
    return 1
  }

  # valida ok
  echo "$resp" | _tg_check_ok_and_get 'ok' >/dev/null
}
