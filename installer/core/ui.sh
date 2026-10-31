#!/usr/bin/env bash

# HyprV Installer - User interface utilities.
#
# This module handles user interaction and plan presentation.
# It does not install packages or modify system configuration.

installer_prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local answer

    while true; do
        if [[ "$default" == "y" ]]; then
            read -r -p "$prompt [Y/n]: " answer || return 2
            answer="${answer:-y}"
        else
            read -r -p "$prompt [y/N]: " answer || return 2
            answer="${answer:-n}"
        fi

        case "${answer,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *) printf 'Please answer yes or no.\n' ;;
        esac
    done
}

installer_choose_config() {
    local choice

    printf '\n'
    printf '========== CONFIGURATION STRATEGY ==========\n'
    printf '1) Lua  - Modern Lua configuration\n'
    printf '2) CONF - Legacy Hyprland configuration\n'
    printf '\n'

    while true; do
        read -r -p "Choose configuration [1/2]: " choice || return 2

        case "$choice" in
            1)
                REPLY="lua"
                return 0
                ;;
            2)
                REPLY="conf"
                return 0
                ;;
            *)
                printf 'Invalid selection. Choose 1 or 2.\n'
                ;;
        esac
    done
}

# Convert prompt return codes into named installer options.
installer_set_yes_no_option() {
    local prompt="$1"
    local variable="$2"
    local status

    if installer_prompt_yes_no "$prompt" n; then
        printf -v "$variable" '%s' "yes"
    else
        status=$?

        case "$status" in
            1)
                printf -v "$variable" '%s' "no"
                ;;
            2)
                return 2
                ;;
            *)
                return "$status"
                ;;
        esac
    fi
}

installer_summary() {
    printf '\n'
    printf '============================================\n'
    printf '             HYPRV INSTALLATION PLAN\n'
    printf '============================================\n'

    printf 'Configuration : %s\n' "$INSTALLER_CONFIG_MODE"
    printf 'NVIDIA support: %s\n' "$INSTALLER_ENABLE_NVIDIA"
    printf 'ROG support   : %s\n' "$INSTALLER_ENABLE_ROG"
    printf 'WiFi powersave: %s\n' "$INSTALLER_DISABLE_WIFI_POWERSAVE"
    printf 'Starship      : %s\n' "$INSTALLER_ENABLE_STARSHIP"

    printf '============================================\n'
    printf '\n'
}
