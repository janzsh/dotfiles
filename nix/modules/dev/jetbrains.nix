{ pkgs, ... }:

{
  # IDEs de JetBrains (unfree; allowUnfree ya está en true en flake.nix).
  home.packages = with pkgs.jetbrains; [
    idea
    webstorm
    pycharm
    goland
    clion
    rider
    datagrip
  ];
}
