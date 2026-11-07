{ pkgs, ... }:

{
  # Cliente MySQL (mysql, mysqldump...) para que DBeaver pueda hacer dumps.
  # `mysql80` fue eliminado (EOL); mysql84 es el LTS vigente.
  home.packages = [ pkgs.mysql84 ];
}
