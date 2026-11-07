{ pkgs, lib, ... }:

{
  # Módulo oficial de NixOS: registra la sesión wayland automáticamente en GDM.
  # swayfx = sway + blur, esquinas redondeadas y sombras (config compatible).
  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
    wrapperFeatures.gtk = true;
  };

  # Portales para grabar pantalla (OBS, compartir en navegador): en sway el
  # ScreenCast lo da xdg-desktop-portal-wlr; sin esto GDM deja el de GNOME.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # El portal wlr necesita un selector de pantalla; sin ninguno instalado
    # (wmenu/wofi/rofi/...) falla con "no output found". slurp (clic en el monitor).
    wlr.settings.screencast = {
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.sway = {
      default = lib.mkForce [ "wlr" "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
  };

  # sway no activa graphical-session.target por sí solo; sin él los servicios
  # de usuario de los portales no arrancan ("Dependency failed for Portal service").
  systemd.user.targets.sway-session = {
    description = "sway compositor session";
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };

  # Reglas udev de brightnessctl: permiten cambiar el brillo sin root (grupo video).
  services.udev.packages = [ pkgs.brightnessctl ];
}
