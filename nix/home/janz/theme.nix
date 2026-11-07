{ config, ... }:

{
  # Sistema de temas en caliente (config/theme): `theme set|next|prev|list`.
  # Enlace directo al repo (como sway/quickshell): añadir o editar un tema no
  # requiere rebuild. El comando queda en el PATH vía sessionPath.
  xdg.configFile."theme".source =
    config.lib.file.mkOutOfStoreSymlink "/home/janz/dotfiles/config/theme";
  home.sessionPath = [ "${config.xdg.configHome}/theme/bin" ];
}
