#!/usr/bin/env bash
# Acciones de Quickshell que dependen del compositor, para que los .qml no
# llamen a swaymsg ni a hyprctl directamente.
#   wmctl.sh focus <id>        enfoca una ventana (id del wm-state.json)
#   wmctl.sh workspace <n>     va al workspace n (1-10)
#   wmctl.sh exit              cierra la sesión
set -u

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    case "${1:-}" in
        focus)     hyprctl eval "dots_focus_address('$2')" >/dev/null ;;
        workspace) hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = $2 }))" >/dev/null ;;
        exit)      hyprctl eval "hl.dispatch(hl.dsp.exit())" >/dev/null ;;
    esac
else
    case "${1:-}" in
        focus)     swaymsg "[con_id=$2] focus" >/dev/null ;;
        workspace) swaymsg workspace number "$2" >/dev/null ;;
        exit)      swaymsg exit >/dev/null ;;
    esac
fi
