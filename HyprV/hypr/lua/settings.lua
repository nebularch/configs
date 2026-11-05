-- Preserve the user's previous HyprV visual and window-management settings.
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 5,
        border_size = 1,
        layout = "dwindle",
        col = {
            active_border = "rgb(cdd6f4)",
            inactive_border = "rgba(595959aa)",
        },
    },
    decoration = {
        rounding = 5,
        blur = {
            enabled = true,
            size = 7,
            passes = 4,
            new_optimizations = true,
        },
    },
    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
    },
    animations = {
        enabled = true,
    },
})
