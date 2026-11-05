#!/usr/bin/env bash

# HyprV Installer - Legacy CONF configuration strategy.
#
# Validates repository-owned legacy configuration and support files.

installer_strategy_conf_validate() {
    local root="${REPO_ROOT:?REPO_ROOT is not set}"
    local file
    local -a required_files=(
        HyprV/hypr/hyprland.conf
        HyprV/hypr/env_var.conf
        HyprV/hypr/media-binds.conf
        HyprV/hyprv_util
        HyprV/hypr/xdg-portal-hyprland
    )

    case "${INSTALLER_ENABLE_NVIDIA:-no}" in
        yes) required_files+=(HyprV/hypr/env_var_nvidia.conf) ;;
    esac

    case "${INSTALLER_ENABLE_ROG:-no}" in
        yes) required_files+=(HyprV/hypr/rog-g15-strix-2021-binds.conf) ;;
    esac

    local missing=()

    for file in "${required_files[@]}"; do
        if [[ ! -f "$root/$file" ]]; then
            missing+=("$file")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        printf '[ERROR] CONF strategy is missing required files:\n' >&2

        for file in "${missing[@]}"; do
            printf '  - %s\n' "$file" >&2
        done

        return 1
    fi

    INSTALLER_STRATEGY_LABEL="CONF"
    return 0
}

installer_strategy_conf_plan() {
    printf 'Configuration strategy: CONF\n'
    printf 'Entry point: HyprV/hypr/hyprland.conf\n'
    printf 'Support: legacy HyprV configuration files\n'
    printf 'Existing user configuration: preserved during planning\n'
}
