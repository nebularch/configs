#!/usr/bin/env bash

# HyprV Installer - Lua configuration strategy.
#
# Validates repository-owned Lua configuration files.
# Private user settings are deliberately left untouched.

installer_strategy_lua_validate() {
    local root="${REPO_ROOT:?REPO_ROOT is not set}"
    local file
    local -a required_files=(
        HyprV/hypr/hyprland.lua
        HyprV/hypr/lua/init.lua
        HyprV/hypr/lua/settings.lua
        HyprV/hypr/lua/environment.lua
        HyprV/hypr/lua/monitors.lua
        HyprV/hypr/lua/input.lua
        HyprV/hypr/lua/animations.lua
        HyprV/hypr/lua/layouts.lua
        HyprV/hypr/lua/windowrules.lua
        HyprV/hypr/lua/gestures.lua
        HyprV/hypr/lua/keybinds.lua
        HyprV/hypr/lua/media.lua
        HyprV/hypr/lua/autostart.lua
    )

    case "${INSTALLER_ENABLE_NVIDIA:-no}" in
        yes) required_files+=(HyprV/hypr/lua/nvidia.lua) ;;
    esac

    case "${INSTALLER_ENABLE_ROG:-no}" in
        yes) required_files+=(HyprV/hypr/lua/rog.lua) ;;
    esac

    local missing=()

    for file in "${required_files[@]}"; do
        if [[ ! -f "$root/$file" ]]; then
            missing+=("$file")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        printf '[ERROR] Lua strategy is missing required files:\n' >&2

        for file in "${missing[@]}"; do
            printf '  - %s\n' "$file" >&2
        done

        return 1
    fi

    INSTALLER_STRATEGY_LABEL="Lua"
    return 0
}

installer_strategy_lua_plan() {
    printf 'Configuration strategy: Lua\n'
    printf 'Entry point: HyprV/hypr/hyprland.lua\n'
    printf 'Modules: modular Lua configuration\n'
    printf 'Private settings: preserved, not modified\n'
}
