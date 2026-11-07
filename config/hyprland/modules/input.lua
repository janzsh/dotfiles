hl.config({
    input = {
        kb_layout = "latam",
        follow_mouse = 1,
        touchpad = {
            tap_to_click = true,
            natural_scroll = true,      -- deslizar hacia abajo "jala" el contenido
            disable_while_typing = true,
        },
    },
})

-- 3 dedos a izquierda/derecha = workspace siguiente/anterior.
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
