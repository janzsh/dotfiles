{ ... }:

{
  imports = [
    ./node.nix
    ./python.nix
    ./go.nix
    ./rust.nix
    ./zig.nix
    ./native-toolchain.nix
    ./mysql.nix
    ./aws.nix
    ./bruno.nix
    ./jetbrains.nix
  ];
}
