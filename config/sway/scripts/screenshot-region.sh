#!/usr/bin/env bash
# Captura por región: congela la pantalla (wayfreeze), deja elegir una región
# con slurp y copia el recorte al portapapeles. Esc cancela.
# Bind: mod+shift+s (config/sway/config).
set -u

if [ "${1:-}" = "select" ]; then
    geom=$(slurp -d -b '#23263466' -c '#ca9ee6ff' -s '#ca9ee622' -w 2) || geom=""
    [ -n "$geom" ] && grim -g "$geom" - | wl-copy --type image/png
    pkill -x wayfreeze
    exit 0
fi

pgrep -x wayfreeze >/dev/null && exit 0   # ya hay una captura en curso
exec wayfreeze --hide-cursor --after-freeze-cmd "$0 select"
