local theme = require("modules.theme")

-- Fondo del tema: "<ruta> fill" o "#rrggbb solid_color" (ver config/theme).
local function wallpaper()
    local bg = theme.bg
    local color = bg:match("^(#%x+) solid_color")
    local path = bg:match("^(.-) fill$")
    hl.exec_cmd("pkill -x swaybg")
    if path then
        hl.exec_cmd("swaybg -m fill -i '" .. path .. "'")
    elseif color then
        hl.exec_cmd("swaybg -c '" .. color .. "'")
    end
end

-- `hyprctl reload` (lo que dispara `theme`) vuelve a pintar el fondo.
hl.on("config.reloaded", wallpaper)

hl.on("hyprland.start", function()
    -- Entorno + sesión systemd: requisito de los portales (OBS/ScreenCast).
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland HYPRLAND_INSTANCE_SIGNATURE DISPLAY")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("systemctl --user start pipewire pipewire-pulse wireplumber")

    wallpaper()
    hl.exec_cmd("quickshell")
    -- wm-state-bridge.sh arranca con hyprland-session.target (servicio de
    -- usuario en nix/home/janz/hyprland.nix, que lo reinicia si muere).
    -- Historial del portapapeles (texto e imágenes) para qs ipc call clipboard
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
