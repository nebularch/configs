#!/usr/bin/env bash

# HyprV Installer - System preflight checks.
#
# This module defines checks only.
# It does not install packages or modify system settings.

installer_preflight() {
    printf '\n[INFO] Running system preflight checks...\n'

    # The installer must run as a regular user.
    if [[ "$EUID" -eq 0 ]]; then
        installer_die "Do not run the installer as root. Use sudo only when required."
    fi

    # HyprV currently targets Arch Linux.
    if [[ ! -f /etc/arch-release ]]; then
        installer_die "Unsupported distribution. Arch Linux is required."
    fi

    # Required system commands.
    local cmd
    for cmd in bash pacman sudo; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            installer_die "Required command is missing: $cmd"
        fi
    done

    # Validate the user's home directory.
    if [[ -z "${HOME:-}" || ! -d "$HOME" || ! -w "$HOME" ]]; then
        installer_die "The home directory is missing or not writable."
    fi

    printf '[OK] Running as a regular user.\n'
    printf '[OK] Arch Linux detected.\n'
    printf '[OK] Required system commands available.\n'
    printf '[OK] User home directory is writable.\n'

    printf '[OK] Preflight checks passed.\n'
}
