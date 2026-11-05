#!/usr/bin/env bash

# HyprV Installer - Package manifest.
#
# This file defines package groups only.
# Package installation and repository detection belong to manager.sh.
#
# Keep optional hardware and integrations in separate groups so the
# installer can build an installation plan from the user's choices.

# General desktop dependencies and utilities.
HYPRV_BASE_PACKAGES=(
    qt5-wayland
    qt5ct
    qt6-wayland
    qt6ct
    qt5-svg
    qt5-quickcontrols2
    qt5-graphicaleffects
    gtk3
    polkit-gnome
    pipewire
    wireplumber
    jq
    wl-clipboard
    cliphist
    python-requests
    pacman-contrib
)

# Core HyprV desktop and applications.
HYPRV_DESKTOP_PACKAGES=(
    hyprland
    kitty
    mako
    waybar
    awww
    swaylock-effects
    wofi
    wlogout
    xdg-desktop-portal-hyprland
    swappy
    grim
    slurp
    thunar
    btop
    firefox
    thunderbird
    mpv
    pamixer
    pavucontrol
    brightnessctl
    bluez
    bluez-utils
    blueman
    network-manager-applet
    gvfs
    thunar-archive-plugin
    file-roller
    papirus-icon-theme
    ttf-jetbrains-mono-nerd
    noto-fonts-emoji
    lxappearance
    xfce4-settings
    nwg-look
    sddm
)

# Packages confirmed to be available from the AUR during the package audit.
# The package manager will still verify availability before installation.
HYPRV_AUR_PACKAGES=(
    swaylock-effects
    wlogout
    supergfxctl
)

# Optional integrations.
HYPRV_STARSHIP_PACKAGES=(
    starship
)

# Optional ASUS ROG hardware support.
HYPRV_ROG_PACKAGES=(
    asusctl
    supergfxctl
    rog-control-center
)

# NVIDIA packages are intentionally not listed yet.
# The legacy nvidia-dkms package was not found during the package audit.
# Driver selection must account for GPU generation and kernel type.
