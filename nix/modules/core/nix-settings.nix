{ ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # allowUnfree y los overlays se fijan en flake.nix al crear `pkgs`
  # (requerido porque el flake pasa una instancia de pkgs ya construida).

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise.automatic = true;

  system.stateVersion = "26.05";
}
