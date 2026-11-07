local theme = require("modules.theme")

-- Equivale a swayfx: borde de 2px, esquinas de 10px, sombra y blur.
hl.config({
    general = {
        gaps_in = 2,        -- sway: inner 4 (entre ventanas) -> 2 por lado
        gaps_out = 5,
        border_size = 2,
        col = {
            active_border = theme.color("mauve"),
            inactive_border = theme.color("surface0"),
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "monocle",     -- modo max por defecto (como `workspace_layout tabbed`)
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,
        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = 0x80000000,
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
        },
    },

    -- El "modo max" no debe dibujar barras de pestañas: si algún día se usan
    -- grupos de Hyprland, tampoco muestran groupbar.
    group = {
        groupbar = { enabled = false },
    },

    animations = { enabled = true },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("linear",       { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

hl.animation({ leaf = "global",     enabled = true, speed = 6,   bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 3.5, bezier = "easeOutQuint", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "linear",       style = "popin 90%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2,   bezier = "easeOutQuint", style = "fade" })
