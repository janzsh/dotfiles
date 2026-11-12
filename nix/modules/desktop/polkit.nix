{ ... }:

{
  security.soteria.enable = true;

  # GNOME ya trae su propio agente en gnome-shell.
  systemd.user.services.polkit-soteria.unitConfig.ConditionEnvironment = "!XDG_CURRENT_DESKTOP=GNOME";
}
