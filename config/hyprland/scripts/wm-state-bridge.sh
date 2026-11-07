#!/usr/bin/env bash
# Traduce los eventos de Hyprland al mismo esquema json que usa sway
# (config/sway/scripts/wm-state-bridge.sh): ~/.cache/wm-state.json, para que
# Quickshell no tenga que saber qué compositor está corriendo.
set -euo pipefail

STATE_FILE="$HOME/.cache/wm-state.json"
SOCK="${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
mkdir -p "$(dirname "$STATE_FILE")"

write_state() {
    # Siempre los 10 workspaces (1-9 y 0). "open" = tiene ventanas.
    local ws clients active
    ws=$(hyprctl -j workspaces)
    clients=$(hyprctl -j clients)
    active=$(hyprctl -j activeworkspace | jq .id)
    jq -n --argjson ws "$ws" --argjson cl "$clients" --argjson act "$active" '
        # Ventanas mapeadas del workspace enfocado, en orden de apertura (el
        # de las "pestañas" de sway), para el selector de ventanas.
        ([$cl[] | select(.mapped and .workspace.id == $act)]
            | sort_by(.stableId)
            | map({app: (.class // "?"), id: .address, title: (.title // ""),
                   focused: (.focusHistoryID == 0)})) as $wins
        | ($wins | reduce .[] as $w ([];
                (map(.app) | index($w.app)) as $i
                | if $i == null then . + [{app: $w.app, id: $w.id, count: 1, focused: $w.focused}]
                  else .[$i].count += 1
                       | (if $w.focused then .[$i].id = $w.id | .[$i].focused = true else . end)
                  end)) as $apps
        | {
            groups: [range(1; 11) as $n
                | ($ws | map(select(.id == $n)) | first) as $w
                | ($w.windows // 0) as $c
                | {name: (if $n == 10 then "0" else ($n | tostring) end),
                   focused: ($n == $act),
                   urgent: false,
                   open: ($c > 0),
                   windows: $c}],
            apps: $apps,
            windows: $wins,
            layout: "hyprland"
        }' > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
}

write_state
# Cualquier evento (workspace, ventanas, foco) vuelve a escribir el estado.
socat -U - "UNIX-CONNECT:$SOCK" | while read -r _; do
    write_state
done
