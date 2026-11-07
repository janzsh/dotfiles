-- Lee el tema que renderiza `theme` (config/theme/templates/hyprland.lua ->
-- ~/.cache/theme/hyprland.lua). Se usa dofile y no require para que un
-- `hyprctl reload` vuelva a leer el archivo recién generado.
local M = {}

-- Valores por defecto (Catppuccin Frappé) por si el tema aún no se ha generado.
local data = {
    bg = "#303446 solid_color",
    colors = {
        mauve = "#ca9ee6", pink = "#f4b8e4", red = "#e78284",
        surface0 = "#414559", surface1 = "#51576d", overlay0 = "#737994",
        mantle = "#292c3c", crust = "#232634",
    },
}

local ok, loaded = pcall(dofile, os.getenv("HOME") .. "/.cache/theme/hyprland.lua")
if ok and type(loaded) == "table" then data = loaded end

M.bg = data.bg

-- "#rrggbb" -> "rgb(rrggbb)" (formato de color de Hyprland).
function M.color(name)
    return "rgb(" .. data.colors[name]:sub(2) .. ")"
end

return M
