{ config, pkgs, ... }:

{
  # El binario de sway lo instala el sistema (nix/modules/desktop/sway.nix).
  # jq es para el bridge de estado (scripts/wm-state-bridge.sh); grim, slurp,
  # wl-clipboard y wayfreeze para capturas por región (scripts/screenshot-region.sh).
  # cliphist: historial del portapapeles; hyprpicker: selector de color
  # (ambos desde el menú del logo de Nix en la barra). brightnessctl: brillo (OSD).
  home.packages = with pkgs; [ jq grim slurp wl-clipboard wayfreeze cliphist hyprpicker brightnessctl ];
  # Enlace directo al repo (como quickshell): editar la config o los scripts
  # no requiere rebuild; sway solo necesita recargarse (mod+shift+c).
  xdg.configFile."sway".source =
    config.lib.file.mkOutOfStoreSymlink "/home/janz/dotfiles/config/sway";
}
