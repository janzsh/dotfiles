-- Config de Hyprland en Lua, modular: cada archivo de modules/ se encarga de
-- una sola cosa. El orden importa poco, salvo `theme` (los demás lo leen).
-- Equivalente de config/sway/config. Recargar: mod+shift+c.

-- Los módulos viven junto a este archivo.
local dir = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$") or "."
package.path = dir .. "/?.lua;" .. package.path

for _, name in ipairs({
    "theme",      -- colores y fondo del tema activo (~/.cache/theme)
    "env",        -- variables de entorno
    "monitors",   -- salidas
    "input",      -- teclado, touchpad, gestos
    "look",       -- gaps, bordes, blur, sombras, animaciones
    "layouts",    -- layout `monocle` (modo max) y alternancia con dwindle
    "rules",      -- reglas de ventanas, capas y workspaces
    "binds",      -- atajos
    "autostart",  -- sesión systemd, quickshell, bridge de estado
}) do
    require("modules." .. name)
end
