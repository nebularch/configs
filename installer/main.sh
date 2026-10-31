#!/usr/bin/env bash

# HyprV Installer - Main entry point.
#
# This file orchestrates the installer.
# Individual modules handle their own responsibilities.

# Resolve paths independently of the user's current directory.
INSTALLER_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

REPO_ROOT="$(
    cd -- "$INSTALLER_DIR/.." &&
    pwd
)"

# Load core modules.
source "$INSTALLER_DIR/core/logging.sh"
source "$INSTALLER_DIR/core/preflight.sh"
source "$INSTALLER_DIR/core/backup.sh"
source "$INSTALLER_DIR/core/restore.sh"
source "$INSTALLER_DIR/core/ui.sh"
source "$INSTALLER_DIR/packages/manager.sh"
source "$INSTALLER_DIR/strategies/manager.sh"
source "$INSTALLER_DIR/deployment/planner.sh"

installer_main() {
    printf '\n'
    printf '============================================\n'
    printf '              HYPRV INSTALLER\n'
    printf '============================================\n'
    printf 'A modular Hyprland configuration toolkit.\n'
    printf '\n'

    # Phase 1: Initialize logging.
    installer_init_logging

    # Phase 2: Validate the environment.
    installer_preflight

    # Phase 3: Collect installation preferences.
    installer_choose_config || {
        installer_die "Configuration selection cancelled."
    }

    INSTALLER_CONFIG_MODE="$REPLY"

    installer_set_yes_no_option \
        "Enable NVIDIA support?" INSTALLER_ENABLE_NVIDIA ||
        installer_die "Input cancelled while selecting NVIDIA support."

    installer_set_yes_no_option \
        "Enable ASUS ROG support?" INSTALLER_ENABLE_ROG ||
        installer_die "Input cancelled while selecting ASUS ROG support."

    installer_set_yes_no_option \
        "Disable WiFi powersave?" INSTALLER_DISABLE_WIFI_POWERSAVE ||
        installer_die "Input cancelled while selecting WiFi settings."

    installer_set_yes_no_option \
        "Configure Starship?" INSTALLER_ENABLE_STARSHIP ||
        installer_die "Input cancelled while selecting Starship."

    # Phase 4: Validate and display the selected configuration strategy.
    if installer_strategy_plan; then
        :
    else
        printf '\n[ERROR] Configuration strategy validation failed.\n' >&2
        return 1
    fi

    # Phase 5: Review the intended configuration deployment.
    #
    # This is a read-only plan. Actual file deployment is a later milestone.
    if installer_deployment_plan; then
        :
    else
        printf '\n[ERROR] Configuration deployment plan is not safe to continue.\n' >&2
        return 1
    fi

    # Phase 6: Build and validate the package plan.
    local package_plan_status

    if installer_prepare_package_plan \
        "$INSTALLER_ENABLE_STARSHIP" "$INSTALLER_ENABLE_ROG"; then
        :
    else
        package_plan_status=$?

        case "$package_plan_status" in
            1)
                printf '\n[ERROR] The package plan contains unavailable packages.\n' >&2
                ;;
            2)
                printf '\n[ERROR] The package plan contains packages requiring repository review.\n' >&2
                ;;
            3)
                printf '\n[ERROR] Some package lookups could not be verified.\n' >&2
                ;;
            *)
                printf '\n[ERROR] Package planning failed (status %d).\n' \
                    "$package_plan_status" >&2
                ;;
        esac

        printf '[INFO] Resolve the package plan issues before continuing.\n'
        return 1
    fi

    # Phase 7: Display the combined configuration summary.
    installer_summary

    # Phase 8: Require explicit confirmation.
    if installer_prompt_yes_no "Does this plan look correct?" n; then
        printf '\n[OK] Plan confirmed.\n'
    else
        status=$?

        case "$status" in
            1)
                printf '\n[INFO] Installation plan declined.\n'
                return 0
                ;;
            2)
                printf '\n[INFO] Installation plan cancelled (EOF).\n'
                return 1
                ;;
            *)
                return "$status"
                ;;
        esac
    fi

    # Planning-only milestone.
    # No packages, services, or desktop configurations are changed here.
    printf '\n'
    printf '[OK] Installer architecture is operational.\n'
    printf '[INFO] This milestone is planning-only.\n'
    printf '[INFO] No installation changes were made.\n'
    printf '[INFO] Log: %s\n' "$INSTALLER_LOG"
}

# Only execute when launched directly.
# Sourcing this file loads functions without starting the installer
# or changing the caller's shell options.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    set -Eeuo pipefail
    installer_main "$@"
fi
