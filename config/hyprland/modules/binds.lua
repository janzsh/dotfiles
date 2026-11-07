local layouts = require("modules.layouts")

local mod = "SUPER"
local sway_scripts = "~/.config/sway/scripts"   -- osd.sh y screenshot son agnósticos del compositor

local function run(cmd) return hl.dsp.exec_cmd(cmd) end

-- Programas y shell
hl.bind(mod .. " + Return", run("kitty"))
hl.bind(mod .. " + M", run("qs ipc call launcher toggle"), { repeating = false })
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + L", run("qs ipc call lock lock"))
hl.bind(mod .. " + SHIFT + S", run(sway_scripts .. "/screenshot-region.sh"))
hl.bind(mod .. " + SHIFT + P", run("qs ipc call power toggle"))
hl.bind(mod .. " + SHIFT + T", run("~/.config/theme/bin/theme next"))
hl.bind(mod .. " + Tab", run("qs ipc call switcher toggle"))
hl.bind(mod .. " + SHIFT + C", run("hyprctl reload"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())

-- Volumen y brillo (con OSD de quickshell)
local osd = { locked = true }
hl.bind("XF86AudioRaiseVolume",  run(sway_scripts .. "/osd.sh volume up"),       osd)
hl.bind("XF86AudioLowerVolume",  run(sway_scripts .. "/osd.sh volume down"),     osd)
hl.bind("XF86AudioMute",         run(sway_scripts .. "/osd.sh volume mute"),     osd)
hl.bind("XF86AudioMicMute",      run(sway_scripts .. "/osd.sh mic-mute"),        osd)
hl.bind("XF86MonBrightnessUp",   run(sway_scripts .. "/osd.sh brightness up"),   osd)
hl.bind("XF86MonBrightnessDown", run(sway_scripts .. "/osd.sh brightness down"), osd)

-- Layout: mod+ctrl+Tab alterna el workspace entre modo max y bsp.
hl.bind(mod .. " + CTRL + Tab", layouts.toggle)
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + space", function() layouts.cycle(1) end)

-- Foco: h/j/k/l o flechas
for key, dir in pairs({ H = "left", J = "down", K = "up", L = "right",
                        left = "left", down = "down", up = "up", right = "right" }) do
    hl.bind(mod .. " + " .. key, function() layouts.focus(dir) end)
end

-- Mover ventana (mod+shift+l está ocupado por el bloqueo, como en sway)
for key, dir in pairs({ H = "left", J = "down", K = "up",
                        left = "left", down = "down", up = "up", right = "right" }) do
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end

-- Redimensionar directo: mod+ctrl+h/j/k/l
local step = 40
local resize = { H = { -step, 0 }, J = { 0, step }, K = { 0, -step }, L = { step, 0 } }
for key, d in pairs(resize) do
    hl.bind(mod .. " + CTRL + " .. key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
end

-- Workspaces 1-10 (la tecla 0 es el 10)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Mover/redimensionar ventanas flotantes con el ratón
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
