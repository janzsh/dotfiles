#!/usr/bin/env bash
# Traduce el stream de eventos de sway al mismo esquema json que usan
# qtile y Quickshell (~/.cache/wm-state.json), para que Quickshell no
# tenga que saber qué compositor está corriendo.
set -euo pipefail

STATE_FILE="$HOME/.cache/wm-state.json"
mkdir -p "$(dirname "$STATE_FILE")"

write_state() {
    # Siempre los 10 workspaces (1-9 y 0). "open" = tiene ventanas (no solo existir).
    jq -n --argjson ws "$(swaymsg -t get_workspaces)" --argjson tree "$(swaymsg -t get_tree)" '
        ([$tree | .. | objects | select(.type? == "workspace" and (.num? // -1) >= 1)
          | {key: (.num | tostring),
             value: ([(.nodes + .floating_nodes)[] | .. | objects | select(.pid? != null)] | length)}]
         | from_entries) as $count
        # Ventanas del workspace enfocado, en orden del árbol (= orden de las
        # pestañas), para el selector de ventanas.
        | ([$tree | .. | objects | select(.type? == "workspace" and (.num? // -1) >= 1)
            | select(any(.. | objects; .focused? == true))
            | [(.nodes + .floating_nodes)[] | .. | objects | select(.pid? != null)
               | {app: (.app_id // .window_properties.class // "?"), id: .id,
                  title: (.name // ""), focused: .focused}]] | first // []) as $wins
        # Apps abiertas en el mismo workspace, una entrada por app (para el
        # dock). `id` es la ventana a enfocar: la enfocada, si la hay.
        | ($wins | reduce .[] as $w ([];
                (map(.app) | index($w.app)) as $i
                | if $i == null then . + [{app: $w.app, id: $w.id, count: 1, focused: $w.focused}]
                  else .[$i].count += 1
                       | (if $w.focused then .[$i].id = $w.id | .[$i].focused = true else . end)
                  end)) as $apps
        | {
            groups: [range(1; 11) as $n
                | ($ws | map(select(.num == $n)) | first) as $w
                | ($count[$n | tostring] // 0) as $c
                | {name: (if $n == 10 then "0" else ($n | tostring) end),
                   focused: ($w.focused // false),
                   urgent: ($w.urgent // false),
                   open: ($c > 0),
                   windows: $c}],
            apps: $apps,
            windows: $wins,
            layout: "sway"
        }' > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
}

write_state
swaymsg -t subscribe -m '["workspace", "window"]' | while read -r _; do
    write_state
done
