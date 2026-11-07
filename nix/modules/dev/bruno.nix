{ pkgs, ... }:

{
  # Bruno: cliente de APIs (alternativa a Postman). Las colecciones son
  # archivos de texto en carpetas, así que se pueden versionar con git.
  home.packages = [ pkgs.bruno ];
}
