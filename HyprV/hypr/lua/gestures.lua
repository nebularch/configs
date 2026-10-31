-- Three-finger horizontal workspace switching.
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

-- Three-finger vertical swipe: toggle the default special workspace.
local function toggle_default_special()
    hl.dispatch(hl.dsp.workspace.toggle_special())
end

hl.gesture({
    fingers = 3,
    direction = "up",
    action = toggle_default_special,
})

hl.gesture({
    fingers = 3,
    direction = "down",
    action = toggle_default_special,
})

-- Original pinch behavior: toggle fullscreen.
hl.gesture({
    fingers = 3,
    direction = "pinchout",
    action = "fullscreen",
})

hl.gesture({
    fingers = 3,
    direction = "pinchin",
    action = "fullscreen",
})
