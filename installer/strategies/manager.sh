#!/usr/bin/env bash

# HyprV Installer - Configuration strategy dispatcher.

STRATEGY_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

source "$STRATEGY_DIR/lua.sh"
source "$STRATEGY_DIR/conf.sh"

installer_strategy_validate() {
    case "${INSTALLER_CONFIG_MODE:-}" in
        lua)
            installer_strategy_lua_validate
            ;;
        conf)
            installer_strategy_conf_validate
            ;;
        *)
            printf '[ERROR] Unknown configuration strategy: %s\n' \
                "${INSTALLER_CONFIG_MODE:-<unset>}" >&2
            return 1
            ;;
    esac
}

installer_strategy_plan() {
    installer_strategy_validate || return 1

    case "$INSTALLER_CONFIG_MODE" in
        lua)
            installer_strategy_lua_plan
            ;;
        conf)
            installer_strategy_conf_plan
            ;;
    esac

    printf 'NVIDIA requested: %s\n' "${INSTALLER_ENABLE_NVIDIA:-no}"
    printf 'ROG requested: %s\n' "${INSTALLER_ENABLE_ROG:-no}"
    printf 'Hardware settings will not be changed during planning.\n'
}
