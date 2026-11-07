{ pkgs, ... }:

{
  # Via overlay rust-overlay (aplicado en flake.nix): nixpkgs suele ir
  # desactualizado frente a la última estable de Rust (sin LTS tampoco).
  home.packages = [ (pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rust-analyzer" ];
  }) ];
}
