#!/usr/bin/env bash

# HyprV Installer - Backup utilities.
#
# Backups are stored outside the repository in the user's state directory.
# Original absolute paths are preserved beneath the backup's files/ directory.

installer_backup_init() {
    local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
    local backup_base="$state_home/hyprv-installer/backups"

    mkdir -p "$backup_base" || {
        printf '[ERROR] Cannot create backup directory: %s\n' "$backup_base" >&2
        return 1
    }

    INSTALLER_BACKUP_DIR="$(
        mktemp -d "$backup_base/backup-$(date +%Y%m%d-%H%M%S)-XXXXXX"
    )" || {
        printf '[ERROR] Cannot create a unique backup directory.\n' >&2
        return 1
    }

    export INSTALLER_BACKUP_DIR

    if ! {
        printf 'HyprV Installer Backup Manifest\n'
        printf 'Created: %s\n' "$(date --iso-8601=seconds)"
        printf 'Hostname: %s\n' "$(hostname)"
        printf '\n'
    } > "$INSTALLER_BACKUP_DIR/manifest.txt"; then
        printf '[ERROR] Cannot create backup manifest.\n' >&2
        return 1
    fi

    printf '[INFO] Backup directory: %s\n' "$INSTALLER_BACKUP_DIR"
}

installer_backup_path() {
    if [[ "$#" -ne 1 ]]; then
        printf '[ERROR] Usage: installer_backup_path /absolute/path\n' >&2
        return 1
    fi

    local source="$1"
    local destination

    # Require absolute paths so the backup layout is unambiguous.
    if [[ "$source" != /* ]]; then
        printf '[ERROR] Backup source must be an absolute path: %s\n' "$source" >&2
        return 1
    fi

    # Never allow the filesystem root itself to be backed up accidentally.
    if [[ "$source" == "/" ]]; then
        printf '[ERROR] Refusing to back up the filesystem root.\n' >&2
        return 1
    fi

    # Reject ambiguous paths and traversal components.
    # This keeps backup paths consistent with restore-path validation.
    case "$source" in
        *//*|*/./*|*/../*|*/.|*/..|*/)
            printf '[ERROR] Ambiguous or unsafe backup path: %s\n' "$source" >&2
            return 1
            ;;
    esac

    # Accept normal files, directories, and even dangling symlinks.
    if [[ ! -e "$source" && ! -L "$source" ]]; then
        printf '[INFO] Nothing to back up; path does not exist: %s\n' "$source"
        return 0
    fi

    # Create a backup session on the first backup request.
    if [[ -z "${INSTALLER_BACKUP_DIR:-}" ]]; then
        installer_backup_init || return 1
    fi

    destination="$INSTALLER_BACKUP_DIR/files$source"

    # Refuse to overwrite an earlier backup within this session.
    if [[ -e "$destination" || -L "$destination" ]]; then
        printf '[ERROR] Backup destination already exists: %s\n' "$destination" >&2
        return 1
    fi

    mkdir -p -- "$(dirname -- "$destination")" || {
        printf '[ERROR] Cannot create backup path for: %s\n' "$source" >&2
        return 1
    }

    # -a preserves symlinks and metadata instead of following the link.
    if ! cp -a -- "$source" "$destination"; then
        printf '[ERROR] Backup failed: %s\n' "$source" >&2
        return 1
    fi

    # Record the mapping using Bash-escaped paths.
    if ! {
        printf 'SOURCE='
        printf '%q' "$source"
        printf ' BACKUP='
        printf '%q' "$destination"
        printf '\n'
    } >> "$INSTALLER_BACKUP_DIR/manifest.txt"; then
        printf '[ERROR] Backup succeeded, but its manifest entry could not be written.\n' >&2
        return 1
    fi

    printf '[OK] Backed up: %s\n' "$source"
}
