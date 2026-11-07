{ pkgs, ... }:

{
  # Necesario para poder usar zsh como shell de login (config en home/janz/zsh.nix).
  programs.zsh.enable = true;

  users.users."janz" = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Juan Zuniga";
    extraGroups = [ "networkmanager" "wheel" "video" ];
  };
}
