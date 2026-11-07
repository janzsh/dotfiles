{ ... }:

{
  # Solo la sesión GNOME: el login lo hace greetd (greetd.nix), ya no GDM.
  services.desktopManager.gnome.enable = true;
}
