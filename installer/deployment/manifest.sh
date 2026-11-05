#!/usr/bin/env bash

# HyprV Installer - Deployment manifest.
#
# This manifest describes intended mappings only.
# It never creates, copies, replaces, or removes files.

installer_load_deployment_manifest() {
    INSTALLER_DEPLOYMENT_IDS=()
    INSTALLER_DEPLOYMENT_SOURCES=()
    INSTALLER_DEPLOYMENT_DESTINATIONS=()
    INSTALLER_DEPLOYMENT_LABELS=()

    case "${INSTALLER_CONFIG_MODE:-}" in
        lua)
            INSTALLER_DEPLOYMENT_IDS=(
                hyprland-entrypoint
                lua-modules
            )

            INSTALLER_DEPLOYMENT_SOURCES=(
                "HyprV/hypr/hyprland.lua"
                "HyprV/hypr/lua"
            )

            INSTALLER_DEPLOYMENT_DESTINATIONS=(
                "$HOME/.config/hypr/hyprland.lua"
                "$HOME/.config/hypr/hyprv"
            )

            INSTALLER_DEPLOYMENT_LABELS=(
                "Hyprland Lua entry point"
                "HyprV Lua module directory"
            )
            ;;

        conf)
            # CONF deployment is intentionally deferred.
            #
            # Its support files span multiple configuration roots.
            # A partial manifest could produce a broken installation.
            return 0
            ;;

        *)
            printf '[ERROR] Cannot load deployment manifest for mode: %s\n' \
                "${INSTALLER_CONFIG_MODE:-<unset>}" >&2
            return 1
            ;;
    esac

    return 0
}
