-- Modo max: cada ventana del workspace ocupa toda el área útil y solo se ve la
-- enfocada, como el tabbed de sway pero sin barra de pestañas.
local M = {}

hl.layout.register("monocle", {
    recalculate = function(ctx)
        for _, target in ipairs(ctx.targets) do
            target:place(ctx.area)
        end
    end,
})

local function monocle_active()
    local ws = hl.get_active_workspace()
    return ws ~= nil and ws.tiled_layout == "monocle"
end

-- Ventanas tileadas del workspace activo, en orden de apertura (el de las
-- "pestañas" de sway).
local function tiled_windows()
    local ws = hl.get_active_workspace()
    local out = {}
    for _, w in ipairs(hl.get_workspace_windows(ws.id)) do
        if w.mapped and not w.floating then out[#out + 1] = w end
    end
    table.sort(out, function(a, b) return a.stable_id < b.stable_id end)
    return out
end

local function raise(win)
    hl.dispatch(hl.dsp.focus({ window = win }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end

-- Siguiente (+1) o anterior (-1) ventana del workspace, dando la vuelta.
function M.cycle(step)
    local wins, active = tiled_windows(), hl.get_active_window()
    if #wins < 2 or active == nil then return end
    for i, w in ipairs(wins) do
        if w.address == active.address then
            raise(wins[(i - 1 + step) % #wins + 1])
            return
        end
    end
end

-- Enfoca una ventana por dirección: en monocle (donde no hay "izquierda" ni
-- "derecha") recorre las ventanas; en dwindle usa el foco direccional.
function M.focus(direction)
    if monocle_active() then
        M.cycle((direction == "left" or direction == "up") and -1 or 1)
    else
        hl.dispatch(hl.dsp.focus({ direction = direction }))
    end
end

-- Alterna el workspace activo entre monocle y dwindle (bsp). Reemplaza a
-- toggle-layout.sh de sway: aquí no hay que reconstruir ningún árbol.
function M.toggle()
    local ws = hl.get_active_workspace()
    if ws == nil then return end
    hl.workspace_rule({
        workspace = tostring(ws.id),
        layout = monocle_active() and "dwindle" or "monocle",
    })
end

-- Para quickshell (dock y selector de ventanas), vía `hyprctl eval`
-- (ver quickshell/wmctl.sh): _G no se usa para nada más.
_G.dots_focus_address = function(address)
    local w = hl.get_window("address:" .. address)
    if w ~= nil then raise(w) end
end

-- Al enfocar una ventana (clic, nueva, cambio de workspace) pasa al frente:
-- en monocle todas comparten el mismo rectángulo.
hl.on("window.active", function()
    if monocle_active() then hl.dispatch(hl.dsp.window.bring_to_top()) end
end)

return M
