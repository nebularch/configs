#!/usr/bin/env bash

declare -ga INSTALLER_DEPLOYMENT_CREATED_PATHS=()
declare -ga INSTALLER_DEPLOYMENT_CREATED_TARGETS=()

installer_deployment_rollback() {
    local failed=0
    local i count path expected actual
    local -a remaining_paths=()
    local -a remaining_targets=()

    count=${#INSTALLER_DEPLOYMENT_CREATED_PATHS[@]}

    if (( count != ${#INSTALLER_DEPLOYMENT_CREATED_TARGETS[@]} )); then
        printf '[ROLLBACK] ERROR: Tracking arrays have inconsistent lengths.\n' >&2
        return 1
    fi

    printf '\n[ROLLBACK] Reverting links created by this deployment...\n'

    for ((i=count - 1; i >= 0; i--)); do
        path=${INSTALLER_DEPLOYMENT_CREATED_PATHS[i]}
        expected=${INSTALLER_DEPLOYMENT_CREATED_TARGETS[i]}

        if [[ ! -e "$path" && ! -L "$path" ]]; then
            printf '[ROLLBACK] ALREADY ABSENT: %s\n' "$path"
            continue
        fi

        if [[ ! -L "$path" ]]; then
            printf '[ROLLBACK] PRESERVED: %s is no longer a symlink.\n' "$path" >&2
            remaining_paths=("$path" "${remaining_paths[@]}")
            remaining_targets=("$expected" "${remaining_targets[@]}")
            failed=1
            continue
        fi

        actual=$(readlink -- "$path") || {
            printf '[ROLLBACK] ERROR: Could not inspect %s.\n' "$path" >&2
            remaining_paths=("$path" "${remaining_paths[@]}")
            remaining_targets=("$expected" "${remaining_targets[@]}")
            failed=1
            continue
        }

        if [[ "$actual" != "$expected" ]]; then
            printf '[ROLLBACK] PRESERVED: %s now points somewhere else.\n' "$path" >&2
            remaining_paths=("$path" "${remaining_paths[@]}")
            remaining_targets=("$expected" "${remaining_targets[@]}")
            failed=1
            continue
        fi

        if rm -- "$path"; then
            printf '[ROLLBACK] Removed: %s\n' "$path"
        else
            printf '[ROLLBACK] ERROR: Could not remove %s.\n' "$path" >&2
            remaining_paths=("$path" "${remaining_paths[@]}")
            remaining_targets=("$expected" "${remaining_targets[@]}")
            failed=1
        fi
    done

    # Keep only unresolved entries so a later rollback attempt can retry.
    INSTALLER_DEPLOYMENT_CREATED_PATHS=("${remaining_paths[@]}")
    INSTALLER_DEPLOYMENT_CREATED_TARGETS=("${remaining_targets[@]}")

    return "$failed"
}
