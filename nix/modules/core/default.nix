{ ... }:

{
  imports = [
    ./boot.nix
    ./locale-time.nix
    ./networking.nix
    ./audio.nix
    ./printing.nix
    ./users.nix
    ./nix-settings.nix
    ./ssh.nix
    ./tailscale.nix
    ./packages.nix
  ];
}
