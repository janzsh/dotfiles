{ pkgs, ... }:

{
  # nixpkgs.config.allowUnfree ya está en true (core/nix-settings.nix), cubre steam.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    localNetworkGameTransfers.openFirewall = true;
  };

  # ProtonUp-Qt: descarga Proton-GE y otras compat tools para Steam/Heroic.
  environment.systemPackages = [ pkgs.protonup-qt ];
}
