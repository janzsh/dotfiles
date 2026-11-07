-- Pantalla del portátil: 1920x1200 a 144 Hz, escala 1.
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1200@144",
    position = "0x0",
    scale    = 1,
})

-- Cualquier otra salida (proyector, monitor externo): resolución preferida,
-- escala automática.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
