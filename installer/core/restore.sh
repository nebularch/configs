#!/usr/bin/env bash

# HyprV Installer - Restoration utilities.
#
# Restores one path from a verified HyprV backup session.
# Existing destinations are never intentionally overwritten.

installer_restore_path() {
    if [[ "$#" -ne 2 ]]; then
        printf '[ERROR] Usage: installer_restore_path BACKUP_DIR /absolute/path\n' >&2
        return 1
    fi

    local backup_dir="$1"
    local source="$2"
    local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
    local backup_base="$state_home/hyprv-installer/backups"
    local base_real
    local session_real
    local session_name
    local backup_path
    local parent
    local stage_dir
    local staged_path
    local relative
    local current
    local component
    local -a components

    # Validate the requested destination path.
    if [[ "$source" != /* || "$source" == "/" ]]; then
        printf '[ERROR] Restore destination must be an absolute non-root path.\n' >&2
        return 1
    fi

    # Reject ambiguous paths and traversal components.
    case "$source" in
        *//*|*/./*|*/../*|*/.|*/..|*/)
            printf '[ERROR] Ambiguous or unsafe destination path: %s\n' "$source" >&2
            return 1
            ;;
    esac

    # The backup root must already exist.
    if [[ ! -d "$backup_base" ]]; then
        printf '[ERROR] HyprV backup directory does not exist: %s\n' "$backup_base" >&2
        return 1
    fi

    # Require an absolute, non-symlink session path.
    if [[ "$backup_dir" != /* || "$backup_dir" == */ || -L "$backup_dir" ]]; then
        printf '[ERROR] Invalid backup session path: %s\n' "$backup_dir" >&2
        return 1
    fi

    # Resolve both paths to prevent ../ and symlink escapes.
    base_real="$(realpath -e -- "$backup_base")" || {
        printf '[ERROR] Cannot resolve HyprV backup directory.\n' >&2
        return 1
    }

    session_real="$(realpath -e -- "$backup_dir")" || {
        printf '[ERROR] Backup session does not exist: %s\n' "$backup_dir" >&2
        return 1
    }

    session_name="$(basename -- "$session_real")"

    # A valid session must be a direct child named backup-*.
    if [[ "$(dirname -- "$session_real")" != "$base_real" ||
          "$session_name" != backup-* ]]; then
        printf '[ERROR] Backup session is outside the approved backup directory.\n' >&2
        return 1
    fi

    # Require genuine session structure, not symlink substitutions.
    if [[ ! -d "$session_real" ||
          ! -f "$session_real/manifest.txt" ||
          -L "$session_real/manifest.txt" ||
          ! -d "$session_real/files" ||
          -L "$session_real/files" ]]; then
        printf '[ERROR] Backup session structure is invalid.\n' >&2
        return 1
    fi

    backup_path="$session_real/files$source"
    parent="$(dirname -- "$source")"

    # Check each intermediate backup component.
    # Intermediate symlinks could redirect the lookup outside files/.
    relative="${source#/}"
    IFS='/' read -r -a components <<< "$relative"
    current="$session_real/files"

    for ((i = 0; i < ${#components[@]} - 1; i++)); do
        component="${components[i]}"
        current="$current/$component"

        if [[ ! -d "$current" || -L "$current" ]]; then
            printf '[ERROR] Backup path has a missing or unsafe parent: %s\n' "$current" >&2
            return 1
        fi
    done

    # Accept regular files, directories, and symlinks at the final component.
    if [[ ! -e "$backup_path" && ! -L "$backup_path" ]]; then
        printf '[ERROR] No backed-up copy exists for: %s\n' "$source" >&2
        return 1
    fi

    # Never create missing destination parent directories implicitly.
    if [[ ! -d "$parent" || ! -w "$parent" ]]; then
        printf '[ERROR] Destination parent is missing or not writable: %s\n' "$parent" >&2
        return 1
    fi

    # Refuse existing files, directories, and dangling symlinks.
    if [[ -e "$source" || -L "$source" ]]; then
        printf '[ERROR] Destination already exists; refusing to overwrite: %s\n' "$source" >&2
        return 1
    fi

    # Stage on the destination filesystem.
    stage_dir="$(mktemp -d "$parent/.hyprv-restore.XXXXXX")" || {
        printf '[ERROR] Cannot create restore staging directory.\n' >&2
        return 1
    }

    staged_path="$stage_dir/restored"

    if ! cp -a -- "$backup_path" "$staged_path"; then
        printf '[ERROR] Could not stage backup copy: %s\n' "$source" >&2
        rm -rf -- "$stage_dir"
        return 1
    fi

    # Recheck before installation.
    if [[ -e "$source" || -L "$source" ]]; then
        printf '[ERROR] Destination appeared during restoration; refusing to overwrite: %s\n' "$source" >&2
        rm -rf -- "$stage_dir"
        return 1
    fi

    # -T treats destination as an exact path.
    # -n prevents replacement if another process creates it meanwhile.
    if ! mv -Tn -- "$staged_path" "$source"; then
        printf '[ERROR] Could not install restored copy: %s\n' "$source" >&2
        rm -rf -- "$stage_dir"
        return 1
    fi

    # A skipped no-clobber move leaves the staged item behind.
    if [[ -e "$staged_path" || -L "$staged_path" ]]; then
        printf '[ERROR] Restore was not installed; destination may already exist: %s\n' "$source" >&2
        rm -rf -- "$stage_dir"
        return 1
    fi

    rmdir -- "$stage_dir" || {
        printf '[WARNING] Restore succeeded, but staging directory remains: %s\n' "$stage_dir" >&2
    }

    printf '[OK] Restored: %s\n' "$source"
}
