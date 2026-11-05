#!/usr/bin/env bash

# HyprV Installer - Package collection.
#
# This module collects selected package groups.
# It does not query repositories or install packages.

installer_load_package_manifest() {
    if [[ "${HYPRV_PACKAGE_MANIFEST_LOADED:-false}" == true ]]; then
        return 0
    fi

    local package_dir
    package_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)" || {
        installer_die "Cannot locate the package manifest directory."
    }

    local manifest="$package_dir/packages.sh"

    [[ -f "$manifest" ]] || {
        installer_die "Package manifest not found: $manifest"
    }

    source "$manifest"
    HYPRV_PACKAGE_MANIFEST_LOADED=true
}

installer_collect_packages() {
    local starship="${1:-no}"
    local rog="${2:-no}"

    case "$starship" in
        yes|no) ;;
        *) installer_die "Invalid Starship selection: $starship" ;;
    esac

    case "$rog" in
        yes|no) ;;
        *) installer_die "Invalid ROG selection: $rog" ;;
    esac

    installer_load_package_manifest

    INSTALLER_REQUESTED_PACKAGES=()

    local -A seen=()
    local package

    for package in "${HYPRV_BASE_PACKAGES[@]}" \
                   "${HYPRV_DESKTOP_PACKAGES[@]}"; do
        if [[ -z "${seen[$package]+present}" ]]; then
            INSTALLER_REQUESTED_PACKAGES+=("$package")
            seen["$package"]=1
        fi
    done

    if [[ "$starship" == yes ]]; then
        for package in "${HYPRV_STARSHIP_PACKAGES[@]}"; do
            if [[ -z "${seen[$package]+present}" ]]; then
                INSTALLER_REQUESTED_PACKAGES+=("$package")
                seen["$package"]=1
            fi
        done
    fi

    if [[ "$rog" == yes ]]; then
        for package in "${HYPRV_ROG_PACKAGES[@]}"; do
            if [[ -z "${seen[$package]+present}" ]]; then
                INSTALLER_REQUESTED_PACKAGES+=("$package")
                seen["$package"]=1
            fi
        done
    fi

    printf '[OK] Collected %d unique package(s).\n' \
        "${#INSTALLER_REQUESTED_PACKAGES[@]}"
}


# Check whether a package is already installed.
installer_package_is_installed() {
    local package="$1"

    pacman -Qq "$package" >/dev/null 2>&1
}

# Check a package against configured pacman repositories.
#
# Return codes:
#   0 - Found.
#   1 - Explicitly reported as not found.
#   2 - Lookup failed for another reason.
installer_lookup_sync_package() {
    local package="$1"
    local info

    if info="$(pacman -Si "$package" 2>&1)"; then
        return 0
    fi

    if grep -Fq "was not found" <<<"$info"; then
        return 1
    fi

    return 2
}

# Read the repository field from yay package metadata.
#
# Return codes:
#   0 - Found; repository is printed.
#   1 - Explicitly reported as not found.
#   2 - Lookup failed or metadata was incomplete.
installer_get_yay_repository() {
    local package="$1"
    local info repository

    if ! info="$(yay -Si "$package" 2>&1)"; then
        if grep -Eiq 'No AUR package found|package .* was not found' <<<"$info"; then
            return 1
        fi
        return 2
    fi

    repository="$(
        printf '%s\n' "$info" |
            awk -F ':' '
                /^[[:space:]]*Repository[[:space:]]*:/ {
                    sub(/^[^:]*:[[:space:]]*/, "")
                    gsub(/[[:space:]]/, "")
                    print
                    exit
                }
            '
    )"

    [[ -n "$repository" ]] || return 2
    printf '%s\n' "$repository"
}

# Check whether a repository is enabled in pacman.conf.
#
# Return codes:
#   0 - Repository is configured.
#   1 - Repository is not configured.
#   2 - Repository list could not be verified.
installer_repository_is_configured() {
    local repository="$1"
    local configured_repositories

    command -v pacman-conf >/dev/null 2>&1 || return 2

    if ! configured_repositories="$(pacman-conf --repo-list 2>/dev/null)"; then
        return 2
    fi

    [[ -n "$configured_repositories" ]] || return 2
    grep -Fxq -- "$repository" <<<"$configured_repositories"
}

# Classify requested packages without installing anything.
installer_classify_packages() {
    command -v pacman >/dev/null 2>&1 || {
        installer_die "pacman is required for package classification."
    }

    INSTALLER_INSTALLED_PACKAGES=()
    INSTALLER_SYNC_PACKAGES=()
    INSTALLER_AUR_PACKAGES=()
    INSTALLER_UNAVAILABLE_PACKAGES=()
    INSTALLER_OTHER_PACKAGES=()
    INSTALLER_UNVERIFIED_PACKAGES=()

    local package repository
    local pacman_status yay_status repository_status

    for package in "${INSTALLER_REQUESTED_PACKAGES[@]}"; do
        if installer_package_is_installed "$package"; then
            INSTALLER_INSTALLED_PACKAGES+=("$package")
            continue
        fi

        if installer_lookup_sync_package "$package"; then
            INSTALLER_SYNC_PACKAGES+=("$package")
            continue
        else
            pacman_status=$?
        fi

        if command -v yay >/dev/null 2>&1; then
            if repository="$(installer_get_yay_repository "$package")"; then
                if [[ "$repository" == aur ]]; then
                    INSTALLER_AUR_PACKAGES+=("$package")
                    continue
                fi

                if installer_repository_is_configured "$repository"; then
                    INSTALLER_SYNC_PACKAGES+=("$package")
                    continue
                else
                    repository_status=$?
                fi

                if (( repository_status == 1 )); then
                    INSTALLER_OTHER_PACKAGES+=("$package")
                else
                    INSTALLER_UNVERIFIED_PACKAGES+=("$package")
                fi
                continue
            else
                yay_status=$?
            fi
        else
            yay_status=2
        fi

        if (( pacman_status == 1 && yay_status == 1 )); then
            INSTALLER_UNAVAILABLE_PACKAGES+=("$package")
        else
            INSTALLER_UNVERIFIED_PACKAGES+=("$package")
        fi
    done

    printf '\n[INFO] Package classification complete.\n'
    printf '  Already installed:       %d\n' "${#INSTALLER_INSTALLED_PACKAGES[@]}"
    printf '  Sync repositories:       %d\n' "${#INSTALLER_SYNC_PACKAGES[@]}"
    printf '  AUR:                     %d\n' "${#INSTALLER_AUR_PACKAGES[@]}"
    printf '  Other repositories:      %d\n' "${#INSTALLER_OTHER_PACKAGES[@]}"
    printf '  Unavailable:             %d\n' "${#INSTALLER_UNAVAILABLE_PACKAGES[@]}"
    printf '  Unverified:              %d\n' "${#INSTALLER_UNVERIFIED_PACKAGES[@]}"
}

# Print a package list, including an explicit empty-state message.
installer_print_package_list() {
    local label="$1"
    shift

    printf '\n%s (%d)\n' "$label" "$#"

    if (( $# == 0 )); then
        printf '  None\n'
        return 0
    fi

    local package
    for package in "$@"; do
        printf '  - %s\n' "$package"
    done
}

# Display the proposed package operations.
# This function is informational only; it never installs packages.
installer_show_package_plan() {
    printf '\n'
    printf '%s\n' '============================================'
    printf '%s\n' '          HYPRV PACKAGE INSTALL PLAN'
    printf '%s\n' '============================================'

    installer_print_package_list \
        "Already installed — will be skipped" \
        "${INSTALLER_INSTALLED_PACKAGES[@]}"

    installer_print_package_list \
        "Official repositories — pending" \
        "${INSTALLER_SYNC_PACKAGES[@]}"

    installer_print_package_list \
        "AUR — pending" \
        "${INSTALLER_AUR_PACKAGES[@]}"

    installer_print_package_list \
        "Other repositories — review required" \
        "${INSTALLER_OTHER_PACKAGES[@]}"

    installer_print_package_list \
        "Unavailable — cannot install" \
        "${INSTALLER_UNAVAILABLE_PACKAGES[@]}"

    installer_print_package_list \
        "Unverified — lookup needs attention" \
        "${INSTALLER_UNVERIFIED_PACKAGES[@]}"

    local pending_count
    pending_count=$((
        ${#INSTALLER_SYNC_PACKAGES[@]} +
        ${#INSTALLER_AUR_PACKAGES[@]} +
        ${#INSTALLER_OTHER_PACKAGES[@]}
    ))

    printf '\n%s\n' '--------------------------------------------'
    printf 'Requested:          %d\n' \
        "${#INSTALLER_REQUESTED_PACKAGES[@]}"
    printf 'Already installed:  %d\n' \
        "${#INSTALLER_INSTALLED_PACKAGES[@]}"
    printf 'Pending:            %d\n' "$pending_count"
    printf 'Unavailable:        %d\n' \
        "${#INSTALLER_UNAVAILABLE_PACKAGES[@]}"

    if (( ${#INSTALLER_UNAVAILABLE_PACKAGES[@]} > 0 )); then
        printf '\n[WARNING] Some packages were confirmed unavailable.\n'
    elif (( ${#INSTALLER_UNVERIFIED_PACKAGES[@]} > 0 )); then
        printf '\n[WARNING] Some package lookups could not be verified.\n'
    elif (( ${#INSTALLER_OTHER_PACKAGES[@]} > 0 )); then
        printf '\n[WARNING] Review packages from other repositories first.\n'
    else
        printf '\n[OK] All requested packages have a recognised source.\n'
    fi

    printf '%s\n' '============================================'
}


# Prepare and display the complete package plan.
#
# Return codes:
#   0 - All requested packages have recognised sources.
#   1 - At least one package is confirmed unavailable.
#   2 - Empty request or packages requiring source review.
#   3 - At least one package could not be verified.
#
# This function never installs packages.
installer_prepare_package_plan() {
    local starship="${1:-no}"
    local rog="${2:-no}"

    installer_collect_packages "$starship" "$rog"

    if (( ${#INSTALLER_REQUESTED_PACKAGES[@]} == 0 )); then
        printf '[ERROR] No packages were requested.\n' >&2
        return 2
    fi

    installer_classify_packages
    installer_show_package_plan

    if (( ${#INSTALLER_UNAVAILABLE_PACKAGES[@]} > 0 )); then
        return 1
    fi

    if (( ${#INSTALLER_UNVERIFIED_PACKAGES[@]} > 0 )); then
        return 3
    fi

    if (( ${#INSTALLER_OTHER_PACKAGES[@]} > 0 )); then
        return 2
    fi

    return 0
}
