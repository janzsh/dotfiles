{ pkgs, lib, ... }:

{
  # Módulo oficial de NixOS: registra la sesión "Hyprland" en GDM junto a sway
  # (se elige en el login) y añade xdg-desktop-portal-hyprland.
  # La config en Lua vive en config/hyprland (ver nix/home/janz/hyprland.nix).
  programs.hyprland = {
    enable = true;
    # El paquete trae dos sesiones en GDM: "Hyprland" y "Hyprland (uwsm-managed)".
    # La segunda necesita las units de uwsm (wayland-session-bindpid@, wayland-wm@);
    # sin esto GDM se queda en negro y vuelve al login.
    withUWSM = true;
  };

  # Portales: Hyprland da el ScreenCast con su propio portal; el resto (selector
  # de archivos, etc.) lo cubre gtk. xdg.portal.config.sway queda intacto.
  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.hyprland = {
      default = lib.mkForce [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
  };

  # Igual que sway-session: Hyprland no activa graphical-session.target por sí
  # solo y sin él los servicios de usuario de los portales no arrancan.
  systemd.user.targets.hyprland-session = {
    description = "Hyprland compositor session";
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };
}
