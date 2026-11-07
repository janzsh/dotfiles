{ pkgs, ... }:

{
  # Navegador dedicado a desarrollo del SaaS (unfree; allowUnfree ya está en true en flake.nix).
  home.packages = [ pkgs.google-chrome ];
}
