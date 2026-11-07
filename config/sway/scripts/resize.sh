#!/usr/bin/env bash
# Redimensiona "moviendo el divisor" hacia la dirección pulsada, como qtile:
# la ventana de la izquierda crece con "derecha" y la de la derecha se achica.
# Uso: resize.sh h|j|k|l
set -u
step=40
tol=12   # margen para gaps/bordes

read -r x y w h wx wy ww wh < <(swaymsg -t get_tree | jq -r '
  [.. | objects | select(.type? == "workspace" and .focus != null and ([.. | objects | select(.focused? == true)] | length > 0))][0] as $ws
  | ($ws | [.. | objects | select(.focused? == true)][0]) as $f
  | "\($f.rect.x) \($f.rect.y) \($f.rect.width) \($f.rect.height) \($ws.rect.x) \($ws.rect.y) \($ws.rect.width) \($ws.rect.height)"')

at_left=$(( x <= wx + tol ))
at_right=$(( x + w >= wx + ww - tol ))
at_top=$(( y <= wy + tol ))
at_bottom=$(( y + h >= wy + wh - tol ))

case "${1:-}" in
    l) (( at_right ))  && cmd="shrink left"  || cmd="grow right" ;;
    h) (( at_left ))   && cmd="shrink right" || cmd="grow left" ;;
    j) (( at_bottom )) && cmd="shrink up"    || cmd="grow down" ;;
    k) (( at_top ))    && cmd="shrink down"  || cmd="grow up" ;;
    *) exit 1 ;;
esac
swaymsg "resize $cmd ${step}px" >/dev/null
