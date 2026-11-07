#!/usr/bin/env bash
# Volumen/brillo + OSD de Quickshell (config/quickshell/OSD.qml).
# Uso: osd.sh volume up|down|mute | osd.sh mic-mute | osd.sh brightness up|down
set -u
step=5
sink=@DEFAULT_AUDIO_SINK@

show_volume() {
    local out vol muted=false
    out=$(wpctl get-volume "$sink") || return
    vol=$(awk '{printf "%d", $2 * 100 + 0.5}' <<<"$out")
    [[ $out == *MUTED* ]] && muted=true
    qs ipc call osd popup volume "$vol" "$muted"
}

show_brightness() {
    local pct
    pct=$(brightnessctl -m | awk -F, '{gsub("%","",$4); print $4}')
    qs ipc call osd popup brightness "$pct" false
}

case "${1:-}" in
    volume)
        case "${2:-}" in
            up)   wpctl set-mute "$sink" 0; wpctl set-volume -l 1.25 "$sink" ${step}%+ ;;
            down) wpctl set-volume "$sink" ${step}%- ;;
            mute) wpctl set-mute "$sink" toggle ;;
        esac
        show_volume ;;
    mic-mute)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
            qs ipc call osd popup mic 0 true
        else
            qs ipc call osd popup mic 100 false
        fi ;;
    brightness)
        case "${2:-}" in
            up)   brightnessctl -q set ${step}%+ ;;
            down) brightnessctl -q set ${step}%- ;;
        esac
        show_brightness ;;
esac
