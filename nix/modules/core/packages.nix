{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unzip
    btop
    fastfetch
    iw
  ];
}
