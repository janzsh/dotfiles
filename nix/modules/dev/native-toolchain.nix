{ pkgs, ... }:

{
  # Toolchain nativo de compilación C/C++: una sola responsabilidad.
  home.packages = [ pkgs.gcc pkgs.gnumake pkgs.cmake ];
}
