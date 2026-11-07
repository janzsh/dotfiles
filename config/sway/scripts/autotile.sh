#!/usr/bin/env bash
# Pseudo-bsp: al enfocar una ventana dentro de un contenedor splith/splitv,
# fija la dirección del próximo split según su forma (más ancha que alta ->
# splith, si no splitv), lo que produce el patrón en espiral de bspwm.
# No toca contenedores tabbed/stacking (el layout por defecto).
set -euo pipefail

retile() {
    [[ -e "${XDG_RUNTIME_DIR:-/tmp}/sway-layout.lock" ]] && return 0
    local info layout w h
    info=$(swaymsg -t get_tree | jq -r '
        def f($p): if .focused then [$p.layout, .rect.width, .rect.height] | @tsv
                   else . as $s | (.nodes[]? | f($s)) end;
        first(f(.) // empty)') || return 0
    [[ -n "$info" ]] || return 0
    read -r layout w h <<<"$info"
    case "$layout" in
        splith|splitv)
            if (( w > h )); then swaymsg splith >/dev/null; else swaymsg splitv >/dev/null; fi ;;
    esac
}

retile
swaymsg -t subscribe -m '["window"]' | jq --unbuffered -r 'select(.change == "focus" or .change == "new") | .change' |
while read -r _; do
    retile
done
