{ config, pkgs, ... }:

{
  # El binario de Hyprland lo instala el sistema (nix/modules/desktop/hyprland.nix).
  # swaybg: fondo de pantalla (Hyprland no trae); socat: eventos del socket de
  # Hyprland para el bridge de estado (scripts/wm-state-bridge.sh). El resto de
  # herramientas (jq, grim, slurp, cliphist, brightnessctl...) las trae sway.nix.
  home.packages = with pkgs; [ swaybg socat ];
  # Enlace directo al repo (como sway/quickshell): editar la config Lua no
  # requiere rebuild; Hyprland la recarga con mod+shift+c.
  xdg.configFile."hypr".source =
    config.lib.file.mkOutOfStoreSymlink "/home/janz/dotfiles/config/hyprland";
}
