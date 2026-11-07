{ pkgs, ... }:

{
  # python314 es el `python3` por defecto en nixos-unstable (última estable).
  home.packages = [ pkgs.python314 ];
}
