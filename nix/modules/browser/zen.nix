{ inputs, pkgs, ... }:

{
  # Paquete directo del flake de terceros (sin módulo home-manager propio,
  # ver flake.nix input zen-browser): zen-beta, la build estable del flake.
  home.packages = [ inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
