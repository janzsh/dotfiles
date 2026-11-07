{ pkgs, ... }:

{
  # Epic Games no tiene cliente nativo en Linux: Heroic (via legendary)
  # es el estándar de facto para Epic + GOG.
  home.packages = [ pkgs.heroic ];
}
