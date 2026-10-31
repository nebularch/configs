local mainMod = "SUPER"

-- Applications and session actions.
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("swaylock"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("wlogout --protocol layer-shell"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("wofi"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("swapwithmaster"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("~/.config/hypr/screenshot.sh"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("~/.config/HyprV/hyprv_util vswitch"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd('sh -c \'hyprctl reload && notify-send "Hyprland Reloaded"\''))

-- Clipboard history.
hl.bind("ALT + V", hl.dsp.exec_cmd("sh -c 'cliphist list | wofi -dmenu | cliphist decode | wl-copy'"))
hl.bind("ALT + DELETE", hl.dsp.exec_cmd("sh -c 'cliphist list | wofi --dmenu | cliphist delete'"))

-- Directional focus.
hl.bind(mainMod .. " + LEFT", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + UP", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + DOWN", hl.dsp.focus({ direction = "down" }))

-- Workspaces 1-9 and 10 (0 key).
for key, workspace in pairs({
    ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5,
    ["6"] = 6, ["7"] = 7, ["8"] = 8, ["9"] = 9, ["0"] = 10,
}) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

-- Workspace scrolling.
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse move/resize.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
