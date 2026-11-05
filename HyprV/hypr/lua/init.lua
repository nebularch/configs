-- HyprV Lua module loader.
-- The local symlink ~/.config/hypr/hyprv points to this directory.

local home = os.getenv("HOME")
local base = home .. "/.config/hypr/hyprv/"
local features_path = home .. "/.config/hypr/hyprv-private/features.lua"

-- Load private hardware feature selection.
local feature_ok, features = pcall(dofile, features_path)

if not feature_ok then
    print("HyprV: optional feature settings unavailable: " .. tostring(features))
    features = {}
elseif type(features) ~= "table" then
    print("HyprV: optional feature settings must return a table.")
    features = {}
end

-- Environment variables must be registered before other configuration.
if features.nvidia == true then
    dofile(base .. "nvidia.lua")
end

-- Core desktop configuration.
dofile(base .. "settings.lua")
dofile(base .. "environment.lua")
dofile(base .. "monitors.lua")
dofile(base .. "input.lua")
dofile(base .. "animations.lua")
dofile(base .. "layouts.lua")
dofile(base .. "windowrules.lua")
dofile(base .. "gestures.lua")
dofile(base .. "keybinds.lua")

-- Hardware-specific keybindings.
if features.rog == true then
    dofile(base .. "rog.lua")
end

-- Remaining desktop functionality.
dofile(base .. "media.lua")
dofile(base .. "autostart.lua")
