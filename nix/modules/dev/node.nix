{ pkgs, ... }:

{
  # Node.js 24 = Active LTS vigente (Node 26 LTS entra el 2026-10-28).
  home.packages = [
    pkgs.nodejs_24
    pkgs.bun
  ];

  # Paquetes globales de npm en el home (el store de Nix es de solo lectura).
  home.sessionVariables.NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  home.sessionPath = [ "$HOME/.npm-global/bin" ];
}
