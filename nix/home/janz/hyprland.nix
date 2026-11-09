{ config, pkgs, lib, ... }:

{
  # El binario de Hyprland lo instala el sistema (nix/modules/desktop/hyprland.nix).
  # swaybg: fondo de pantalla (Hyprland no trae); socat: eventos del socket de
  # Hyprland para el bridge de estado (scripts/wm-state-bridge.sh). El resto de
  # herramientas (jq, grim, slurp, cliphist, brightnessctl...) las trae sway.nix.
  home.packages = with pkgs; [ swaybg socat ];
  # Enlace directo al repo (como sway/quickshell): editar la config Lua no
  # requiere rebuild; Hyprland la recarga con mod+shift+c.
  xdg.configFile."hypr".source =
    config.lib.file.mkOutOfStoreSymlink "/home/janz/dotfiles/config/hyprland";

  # El bridge como servicio y no con exec_cmd: si muere (socat pierde el
  # socket, lo matan junto a una terminal...) systemd lo levanta otra vez en
  # vez de dejar los workspaces de Quickshell congelados hasta el próximo login.
  # HYPRLAND_INSTANCE_SIGNATURE llega por el import-environment de autostart.lua.
  systemd.user.services.wm-state-bridge = {
    Unit = {
      Description = "Estado de Hyprland para Quickshell (~/.cache/wm-state.json)";
      PartOf = [ "hyprland-session.target" ];
      # Sin límite de reintentos: Restart=always + RestartSec cubre los bucles.
      StartLimitIntervalSec = 0;
    };
    Service = {
      ExecStart = "${config.xdg.configHome}/hypr/scripts/wm-state-bridge.sh";
      Restart = "always";
      RestartSec = 1;
      # hyprctl viene del sistema (programs.hyprland).
      Environment = [
        "PATH=${lib.makeBinPath (with pkgs; [ bash coreutils jq socat ])}:/run/current-system/sw/bin"
      ];
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
