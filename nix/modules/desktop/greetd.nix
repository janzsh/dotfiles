{ config, lib, pkgs, ... }:

let
  # Sesiones disponibles: las mismas .desktop que veía GDM (Hyprland, sway,
  # GNOME). Se vuelcan a un JSON que lee el greeter; hyprland.desktop se omite
  # porque la variante uwsm es la que se usa.
  sessionsDir = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
  userName = "janz";

  greeterConfig = pkgs.runCommand "greeter-config.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
    for f in ${sessionsDir}/*.desktop; do
      [ "$(basename "$f")" = hyprland.desktop ] && continue
      jq -n \
        --arg name "$(sed -n 's/^Name=//p' "$f" | head -1)" \
        --arg exec "$(sed -n 's/^Exec=//p' "$f" | head -1)" \
        --arg dn "$(sed -n 's/^DesktopNames=//p' "$f" | head -1)" \
        '{ name: $name, exec: $exec, desktopNames: $dn }'
    done | jq -s \
      --arg user ${userName} \
      --arg display ${lib.escapeShellArg config.users.users.${userName}.description} \
      '{ user: $user, displayName: $display, sessions: . }' > $out
  '';

  # Config del greeter (repo) + Theme y LoadingRing compartidos con el shell.
  greeterDir = pkgs.runCommand "greeter-qml" { } ''
    mkdir -p $out
    cp ${../../../config/greeter/shell.qml} $out/shell.qml
    cp ${../../../config/quickshell/Theme.qml} $out/Theme.qml
    cp ${../../../config/quickshell/LoadingRing.qml} $out/LoadingRing.qml
  '';

  greeterCmd = pkgs.writeShellScript "greeter" ''
    export HOME=/var/cache/greeter
    export GREETER_CONFIG=${greeterConfig}
    export GREETER_STATE=/var/cache/greeter/last-session
    export QT_QPA_PLATFORM=wayland
    # Teclado del greeter: el mismo que el sistema (latam = la-latin1 de la consola).
    export XKB_DEFAULT_LAYOUT=${config.services.xserver.xkb.layout}
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    exec ${pkgs.cage}/bin/cage -d -s -m last -- ${pkgs.quickshell}/bin/qs -p ${greeterDir}
  '';
in
{
  # Sustituye a GDM: greetd lanza el greeter (Quickshell dentro de cage) y,
  # tras autenticar, la sesión elegida. GNOME sigue instalado como sesión.
  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "greeter";
      command = "${greeterCmd}";
    };
  };

  # Estado del greeter (última sesión elegida) y HOME para Qt/Quickshell.
  # El tema activo se copia a .cache/theme (lo escribe janz desde `theme`, ver
  # config/theme/bin/theme) y Theme.qml del greeter lo lee desde su HOME.
  systemd.tmpfiles.rules = [
    "d /var/cache/greeter 0755 greeter greeter -"
    "d /var/cache/greeter/.cache 0755 greeter greeter -"
    "d /var/cache/greeter/.cache/theme 0755 ${userName} users -"
  ];

  # El greeter corre como usuario de sistema: necesita la fuente instalada a
  # nivel de sistema (la de home-manager no le llega).
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  # Desbloquea gnome-keyring al iniciar sesión (antes lo hacía GDM).
  security.pam.services.greetd.enableGnomeKeyring = true;
}
