{ pkgs, ... }:

{
  imports = [
    ../../modules/dev
    ../../modules/multimedia
    ../../modules/browser
    ./git.nix
    ./vscodium.nix
    ./antigravity-cli.nix
    ./opencode.nix
    ./codex.nix
    ./ollama.nix
    ./obsidian.nix
    ./libreoffice.nix
    ./sway.nix
    ./hyprland.nix
    ./quickshell.nix
    ./kitty.nix
    ./neovim.nix
    ./theme.nix
    ./zsh.nix
    ./discord.nix
    ./xdg.nix
  ];

  home.username = "janz";
  home.homeDirectory = "/home/janz";
  home.stateVersion = "26.05";

  # foot queda como terminal de respaldo (sway usa kitty, ver kitty.nix)
  # + claude-code, que ya estaba instalado en el configuration.nix original.
  home.packages = [ pkgs.foot pkgs.claude-code pkgs.dbeaver-bin pkgs.bitwarden-desktop ];

  programs.home-manager.enable = true;
}
