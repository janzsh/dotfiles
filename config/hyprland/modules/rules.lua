-- Capas de quickshell: blur solo donde hay píxeles opacos, como los
-- layer_effects de sway.
for _, ns in ipairs({ "qs-bar", "qs-dock", "qs-switcher", "quickshell-power", "quickshell-launcher" }) do
    hl.layer_rule({
        name = "blur-" .. ns,
        match = { namespace = "^" .. ns .. "$" },
        blur = true,
        ignore_alpha = 0,
    })
end

-- Ignora las peticiones de maximizar de las apps.
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- smart_borders de sway: una sola ventana tileada ocupa todo, sin borde ni
-- esquinas redondeadas.
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
