#!/usr/bin/env bash

# HyprV Installer - Logging utilities.
#
# This module defines functions only.
# The main installer decides when logging starts.

installer_die() {
    printf '\n[ERROR] %s\n' "$*" >&2
    exit 1
}

installer_init_logging() {
    [[ -n "${HOME:-}" && -d "$HOME" ]] || {
        installer_die "A valid user home directory is required."
    }

    local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
    local log_dir="$state_home/hyprv-installer/logs"

    mkdir -p "$log_dir" || {
        installer_die "Cannot create log directory: $log_dir"
    }

    INSTALLER_LOG="$(mktemp "$log_dir/install-$(date +%Y%m%d-%H%M%S)-XXXXXX.log")" || {
        installer_die "Cannot create installer log."
    }

    export INSTALLER_LOG

    # Record both standard output and standard error.
    exec > >(tee -a "$INSTALLER_LOG") 2>&1

    printf '[INFO] HyprV Installer logging initialized.\n'
    printf '[INFO] Log file: %s\n' "$INSTALLER_LOG"
}
