hl.window_rule({
    name = "hyprv-floating-apps",
    match = {
        class = "^(pavucontrol|blueman-manager|nm-connection-editor|thunar|chromium|btop|update-sys)$",
    },
    float = true,
})

hl.window_rule({
    name = "hyprv-standard-opacity",
    match = {
        class = "^(kitty|thunar|VSCodium|wofi)$",
    },
    opacity = "0.8 override 0.8 override",
})

hl.window_rule({
    name = "hyprv-viewnior-opacity",
    match = {
        class = "^(viewnior)$",
    },
    opacity = "0.95 override 0.95 override",
})

hl.window_rule({
    name = "hyprv-wofi-no-animation",
    match = {
        class = "^(wofi)$",
    },
    no_anim = true,
})
