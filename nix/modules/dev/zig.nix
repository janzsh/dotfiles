{ pkgs, inputs, ... }:

{
  # Via flake input zig-overlay: nixpkgs suele ir desactualizado frente a
  # la última release estable de ziglang.org (Zig tampoco tiene LTS).
  home.packages = [ inputs.zig-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
