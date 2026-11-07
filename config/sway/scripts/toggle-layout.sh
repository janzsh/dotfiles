#!/usr/bin/env bash
# mod+Tab: alterna TODO el workspace enfocado entre
#   - tabbed: todas las ventanas como pestañas de un único contenedor
#   - bsp:    ventanas repartidas en espiral (como lo haría autotile.sh)
# `layout toggle` de sway solo cambia el contenedor enfocado, por eso se
# reconstruye el árbol: se sacan las ventanas a un workspace temporal y se
# vuelven a meter una a una en el workspace original.
set -euo pipefail

LOCK="${XDG_RUNTIME_DIR:-/tmp}/sway-layout.lock"   # pausa autotile.sh
TMP="__layout_tmp"
[[ -e "$LOCK" ]] && exit 0
touch "$LOCK"
trap 'rm -f "$LOCK"' EXIT

sw() { swaymsg "$@" >/dev/null; }

ws=$(swaymsg -t get_tree | jq -c '
    first(.. | objects | select(.type? == "workspace" and any(.. | objects; .focused? == true)))')
name=$(jq -r .name <<<"$ws")
mapfile -t ids < <(jq -r '[.nodes[] | .. | objects
    | select(.type? == "con" and (.nodes | length) == 0 and .pid? != null) | .id] | .[]' <<<"$ws")
focus=$(jq -r '[.nodes[] | .. | objects | select(.focused? == true) | .id] | first // empty' <<<"$ws")
n=${#ids[@]}
(( n >= 1 )) || exit 0

# Con workspace_layout tabbed la pila vive en un contenedor hijo del workspace.
if jq -e '.layout == "tabbed" or ((.nodes | length) == 1 and .nodes[0].layout == "tabbed")' <<<"$ws" >/dev/null
then mode=bsp; else mode=tabbed; fi

for id in "${ids[@]}"; do sw "[con_id=$id] move container to workspace $TMP"; done

sw "[con_id=${ids[0]}] move container to workspace \"$name\""
if [[ $mode == tabbed ]]; then
    sw "[con_id=${ids[0]}] layout tabbed"
    for id in "${ids[@]:1}"; do sw "[con_id=$id] move container to workspace \"$name\""; done
else
    sw "[con_id=${ids[0]}] layout splith"
    for ((i = 1; i < n; i++)); do
        prev=${ids[i-1]}
        sw "[con_id=$prev] focus"
        read -r w h < <(swaymsg -t get_tree | jq -r --argjson p "$prev" \
            '.. | objects | select(.id? == $p) | "\(.rect.width) \(.rect.height)"')
        if (( w > h )); then sw splith; else sw splitv; fi
        sw "[con_id=${ids[i]}] move container to workspace \"$name\""
    done
fi
[[ -n "$focus" ]] && sw "[con_id=$focus] focus"
