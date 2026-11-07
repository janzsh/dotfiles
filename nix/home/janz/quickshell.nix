{ config, pkgs, ... }:

{
  home.packages = [ pkgs.quickshell ];
  # Enlace directo al repo (no a la tienda de Nix): quickshell recarga solo al
  # editar los .qml, sin necesidad de rebuild.
  xdg.configFile."quickshell".source =
    config.lib.file.mkOutOfStoreSymlink "/home/janz/dotfiles/config/quickshell";
}
