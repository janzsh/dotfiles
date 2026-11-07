{ pkgs, ... }:

{
  # `go` apunta siempre a la última estable soportada en nixos-unstable
  # (Go no tiene LTS, y las versiones pinneadas tipo go_1_25 se eliminan
  # del canal en cuanto quedan EOL).
  home.packages = [ pkgs.go ];
}
