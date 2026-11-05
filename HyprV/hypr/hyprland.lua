-- HyprV Lua entry point.
-- Public modules are loaded through ~/.config/hypr/hyprv.
-- Machine-specific monitor settings stay outside the repository.

local config_dir = os.getenv("HOME") .. "/.config/hypr"

dofile(config_dir .. "/hyprv/init.lua")

local private_monitors = config_dir .. "/hyprv-private/monitors.lua"
local ok, err = pcall(dofile, private_monitors)

if not ok then
    print("HyprV: private monitor override not loaded: " .. tostring(err))
end
