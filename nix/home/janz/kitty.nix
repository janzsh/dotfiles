{ pkgs, ... }:

{
  # La config vive en config/kitty (paleta compartida con quickshell).
  home.packages = [
    pkgs.kitty
    pkgs.nerd-fonts.jetbrains-mono
  ];

  fonts.fontconfig.enable = true;

  xdg.configFile."kitty".source = ../../../config/kitty;
}
