#!/usr/bin/env bash

# HyprV Installer - Read-only deployment planner.
#
# Classifies intended destinations without changing the filesystem.

DEPLOYMENT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

source "$DEPLOYMENT_DIR/manifest.sh"

# Check destination path structure without following symlinked parents.
#
# Return code:
#   0 - Parent path is safe to inspect.
#   1 - Path is malformed or contains an unsafe parent component.
installer_deployment_parent_is_safe() {
    local destination="$1"
    local current="/"
    local component
    local index
    local last_index
    local -a components=()

    [[ "$destination" == /* ]] || return 1
    [[ "$destination" != "/" && "$destination" != */ ]] || return 1

    # Reject line-control characters before parsing the path.
    [[ "$destination" != *$'\n'* ]] || return 1
    [[ "$destination" != *$'\r'* ]] || return 1

    IFS='/' read -r -a components <<< "$destination"

    last_index=$((${#components[@]} - 1))

    for ((index = 1; index <= last_index; index++)); do
        component="${components[$index]}"

        [[ -n "$component" ]] || return 1
        [[ "$component" != "." && "$component" != ".." ]] || return 1

        # The final component is the destination itself.
        (( index == last_index )) && break

        current="${current%/}/$component"

        # Never traverse a symlink while inspecting destination parents.
        [[ ! -L "$current" ]] || return 1

        if [[ -e "$current" ]]; then
            [[ -d "$current" ]] || return 1
        else
            # Remaining components cannot exist beneath a missing parent.
            break
        fi
    done

    return 0
}

# Classify one source/destination pair.
#
# Output:
#   MISSING    Destination does not exist.
#   MATCH      Destination symlink resolves to the intended source.
#   IDENTICAL  Existing regular file has identical content.
#   CONFLICT  Existing destination differs or has an unsafe type.
#
# Return code:
#   0 - Classification completed.
#   1 - Invalid or unavailable source.
installer_deployment_classify() {
    local source="$1"
    local destination="$2"
    local resolved_source
    local resolved_destination

    if [[ ! -e "$source" && ! -L "$source" ]]; then
        printf '[ERROR] Deployment source is missing: %s\n' "$source" >&2
        return 1
    fi

    resolved_source="$(realpath -e -- "$source" 2>/dev/null)" || {
        printf '[ERROR] Cannot resolve deployment source: %s\n' "$source" >&2
        return 1
    }

    if ! installer_deployment_parent_is_safe "$destination"; then
        printf 'CONFLICT\n'
        return 0
    fi

    if [[ ! -e "$destination" && ! -L "$destination" ]]; then
        printf 'MISSING\n'
        return 0
    fi

    # A symlink must resolve to the exact intended source.
    # Dangling symlinks are conflicts, never treated as missing.
    if [[ -L "$destination" ]]; then
        resolved_destination="$(
            realpath -e -- "$destination" 2>/dev/null
        )" || {
            printf 'CONFLICT\n'
            return 0
        }

        if [[ "$resolved_destination" == "$resolved_source" ]]; then
            printf 'MATCH\n'
        else
            printf 'CONFLICT\n'
        fi

        return 0
    fi

    # Regular files can be recognized as identical.
    if [[ -f "$source" && -f "$destination" ]]; then
        if cmp -s -- "$source" "$destination"; then
            printf 'IDENTICAL\n'
        else
            printf 'CONFLICT\n'
        fi

        return 0
    fi

    # Directories are only considered managed when linked to the source.
    # Never recursively adopt or compare an existing directory.
    printf 'CONFLICT\n'
    return 0
}

installer_deployment_plan() {
    local mode="${INSTALLER_CONFIG_MODE:-}"
    local root="${REPO_ROOT:?REPO_ROOT is not set}"
    local index
    local source
    local destination
    local label
    local status

    installer_load_deployment_manifest || return 1

    printf '\n'
    printf '%s\n' '========== DEPLOYMENT PLAN =========='
    printf 'Configuration mode: %s\n' "$mode"

    if [[ "$mode" == conf ]]; then
        printf '[DEFERRED] CONF deployment mappings are not defined yet.\n'
        printf '[INFO] No CONF destinations were evaluated or changed.\n'
        printf '%s\n' '====================================='
        return 0
    fi

    local missing_count=0
    local match_count=0
    local identical_count=0
    local conflict_count=0

    for index in "${!INSTALLER_DEPLOYMENT_IDS[@]}"; do
        source="$root/${INSTALLER_DEPLOYMENT_SOURCES[$index]}"
        destination="${INSTALLER_DEPLOYMENT_DESTINATIONS[$index]}"
        label="${INSTALLER_DEPLOYMENT_LABELS[$index]}"

        if ! status="$(
            installer_deployment_classify "$source" "$destination"
        )"; then
            printf '[ERROR] Cannot plan: %s\n' "$label" >&2
            return 1
        fi

        printf '\n[%s] %s\n' "$status" "$label"
        printf '  Source:      %s\n' "$source"
        printf '  Destination: %s\n' "$destination"

        case "$status" in
            MISSING) ((missing_count += 1)) ;;
            MATCH) ((match_count += 1)) ;;
            IDENTICAL) ((identical_count += 1)) ;;
            CONFLICT) ((conflict_count += 1)) ;;
            *)
                printf '[ERROR] Unexpected deployment status: %s\n' \
                    "$status" >&2
                return 1
                ;;
        esac
    done

    printf '\n'
    printf 'Summary:\n'
    printf '  Missing:   %d\n' "$missing_count"
    printf '  Matching:  %d\n' "$match_count"
    printf '  Identical: %d\n' "$identical_count"
    printf '  Conflicts: %d\n' "$conflict_count"

    printf '[INFO] Dry run only. No filesystem changes were made.\n'
    printf '%s\n' '====================================='

    (( conflict_count == 0 ))
}
