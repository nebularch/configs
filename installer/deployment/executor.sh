#!/usr/bin/env bash

# Requires planner.sh to have been sourced first.
# This executor only creates symlinks at destinations proven to be missing.

_INSTALLER_DEPLOYMENT_EXECUTOR_DIR=$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd
) || return 1

source "$_INSTALLER_DEPLOYMENT_EXECUTOR_DIR/rollback.sh"
unset _INSTALLER_DEPLOYMENT_EXECUTOR_DIR


INSTALLER_DEPLOYMENT_LAST_CREATED_PATH=""
INSTALLER_DEPLOYMENT_LAST_CREATED_TARGET=""

installer_deployment_cleanup_stage() {
    local stage=$1

    # The staged link is ours; no destination path is removed here.
    if [[ -L "$stage/link" ]]; then
        rm -- "$stage/link" || return 1
    fi

    rmdir -- "$stage"
}

installer_deployment_create_link() {
    local source=$1
    local destination=$2
    local parent stage resolved_source resolved_destination

    INSTALLER_DEPLOYMENT_LAST_CREATED_PATH=""
    INSTALLER_DEPLOYMENT_LAST_CREATED_TARGET=""

    parent=$(dirname -- "$destination") || return 1

    stage=$(mktemp -d -- "$parent/.hyprv-deploy.XXXXXX") || {
        printf '[DEPLOY] ERROR: Could not create staging directory in %s.\n' "$parent" >&2
        return 1
    }

    if ! ln -s -- "$source" "$stage/link"; then
        printf '[DEPLOY] ERROR: Could not stage symlink for %s.\n' "$destination" >&2
        installer_deployment_cleanup_stage "$stage" || true
        return 1
    fi

    if ! mv -Tn -- "$stage/link" "$destination"; then
        printf '[DEPLOY] ERROR: Could not move staged link into place: %s\n' "$destination" >&2
        installer_deployment_cleanup_stage "$stage" || true
        return 1
    fi

    # GNU mv -n can return success without moving anything.
    # The staged link must have disappeared for the move to count.
    if [[ -e "$stage/link" || -L "$stage/link" ]]; then
        printf '[DEPLOY] ERROR: Destination appeared before creation: %s\n' "$destination" >&2
        installer_deployment_cleanup_stage "$stage" || true
        return 1
    fi

    # Register immediately so rollback can handle a later verification failure.
    INSTALLER_DEPLOYMENT_LAST_CREATED_PATH=$destination
    INSTALLER_DEPLOYMENT_LAST_CREATED_TARGET=$source

    if [[ ! -L "$destination" ]]; then
        printf '[DEPLOY] ERROR: Created destination is not a symlink: %s\n' "$destination" >&2
        installer_deployment_cleanup_stage "$stage" || true
        return 1
    fi

    if [[ "$(readlink -- "$destination")" != "$source" ]]; then
        printf '[DEPLOY] ERROR: Symlink target verification failed: %s\n' "$destination" >&2
        installer_deployment_cleanup_stage "$stage" || true
        return 1
    fi

    resolved_source=$(realpath -e -- "$source") || {
        printf '[DEPLOY] ERROR: Source no longer resolves: %s\n' "$source" >&2
        installer_deployment_cleanup_stage "$stage" || true
        return 1
    }

    resolved_destination=$(realpath -e -- "$destination") || {
        printf '[DEPLOY] ERROR: Created symlink does not resolve: %s\n' "$destination" >&2
        installer_deployment_cleanup_stage "$stage" || true
        return 1
    }

    if [[ "$resolved_source" != "$resolved_destination" ]]; then
        printf '[DEPLOY] ERROR: Resolved symlink target does not match source: %s\n' "$destination" >&2
        installer_deployment_cleanup_stage "$stage" || true
        return 1
    fi

    installer_deployment_cleanup_stage "$stage" || {
        printf '[DEPLOY] WARNING: Could not clean staging directory: %s\n' "$stage" >&2
        return 1
    }

    return 0
}

installer_deployment_execute() {
    local i count source destination parent state source_real
    local failed=0
    local -A seen_destinations=()
    local -a plan_sources=()
    local -a plan_destinations=()
    local -a plan_actions=()

    if (( ${#INSTALLER_DEPLOYMENT_CREATED_PATHS[@]} !=
          ${#INSTALLER_DEPLOYMENT_CREATED_TARGETS[@]} )); then
        printf '[DEPLOY] ERROR: Rollback tracking arrays have inconsistent lengths.\n' >&2
        return 1
    fi

    if (( ${#INSTALLER_DEPLOYMENT_CREATED_PATHS[@]} > 0 )); then
        printf '[DEPLOY] ERROR: Unresolved rollback records exist.\n' >&2
        printf '[DEPLOY] Retry rollback before starting another deployment.\n' >&2
        return 1
    fi

    INSTALLER_DEPLOYMENT_CREATED_PATHS=()
    INSTALLER_DEPLOYMENT_CREATED_TARGETS=()

    if ! declare -F installer_load_deployment_manifest >/dev/null ||
       ! declare -F installer_deployment_classify >/dev/null ||
       ! declare -F installer_deployment_parent_is_safe >/dev/null; then
        printf '[DEPLOY] ERROR: Source planner.sh before executor.sh.\n' >&2
        return 1
    fi

    if ! installer_load_deployment_manifest; then
        printf '[DEPLOY] ERROR: Could not load deployment manifest.\n' >&2
        return 1
    fi

    count=${#INSTALLER_DEPLOYMENT_IDS[@]}

    if [[ "${INSTALLER_CONFIG_MODE:-}" == "conf" && "$count" -eq 0 ]]; then
        printf '[DEPLOY] CONF deployment is deferred; no changes made.\n'
        return 0
    fi

    if (( count == 0 )); then
        printf '[DEPLOY] ERROR: Deployment manifest is empty.\n' >&2
        return 1
    fi

    if (( ${#INSTALLER_DEPLOYMENT_SOURCES[@]} != count ||
          ${#INSTALLER_DEPLOYMENT_DESTINATIONS[@]} != count )); then
        printf '[DEPLOY] ERROR: Deployment manifest arrays have inconsistent lengths.\n' >&2
        return 1
    fi

    printf '\n[DEPLOY] Preflighting the complete deployment...\n'

    # Phase one: validate every mapping before creating anything.
    for ((i=0; i<count; i++)); do
        source=${INSTALLER_DEPLOYMENT_SOURCES[i]}
        destination=${INSTALLER_DEPLOYMENT_DESTINATIONS[i]}

        if [[ -z "$source" || -z "$destination" ]]; then
            printf '[DEPLOY] BLOCKED: Empty source or destination in manifest entry %s.\n' \
                "${INSTALLER_DEPLOYMENT_IDS[i]}" >&2
            return 1
        fi

        if [[ -n "${seen_destinations[$destination]+present}" ]]; then
            printf '[DEPLOY] BLOCKED: Duplicate destination: %s\n' "$destination" >&2
            return 1
        fi
        seen_destinations["$destination"]=1

        if [[ "$source" != /* ]]; then
            if [[ -z "${REPO_ROOT:-}" ]]; then
                printf '[DEPLOY] ERROR: REPO_ROOT is not set.\n' >&2
                return 1
            fi

            source="${REPO_ROOT}/$source"
        fi

        source_real=$(realpath -e -- "$source") || {
            printf '[DEPLOY] BLOCKED: Source is missing or unresolved: %s\n' "$source" >&2
            return 1
        }

        if ! installer_deployment_parent_is_safe "$destination"; then
            printf '[DEPLOY] BLOCKED: Unsafe destination path: %s\n' "$destination" >&2
            return 1
        fi

        parent=$(dirname -- "$destination")

        if [[ ! -d "$parent" || ! -w "$parent" ]]; then
            printf '[DEPLOY] BLOCKED: Destination parent must exist and be writable: %s\n' "$parent" >&2
            return 1
        fi

        state=$(installer_deployment_classify "$source_real" "$destination") || {
            printf '[DEPLOY] BLOCKED: Could not classify destination: %s\n' "$destination" >&2
            return 1
        }

        case "$state" in
            MISSING)
                plan_actions[i]=LINK
                printf '[DEPLOY] LINK: %s\n' "$destination"
                ;;
            MATCH|IDENTICAL)
                plan_actions[i]=SKIP
                printf '[DEPLOY] SKIP (%s): %s\n' "$state" "$destination"
                ;;
            CONFLICT)
                printf '[DEPLOY] BLOCKED: Existing destination conflicts: %s\n' "$destination" >&2
                return 1
                ;;
            *)
                printf '[DEPLOY] BLOCKED: Unknown destination state %s for %s\n' \
                    "$state" "$destination" >&2
                return 1
                ;;
        esac

        plan_sources[i]=$source_real
        plan_destinations[i]=$destination
    done

    printf '[DEPLOY] Preflight passed. Applying the plan...\n'

    # Phase two: apply only the preflighted LINK actions.
    for ((i=0; i<count; i++)); do
        [[ "${plan_actions[i]}" == "LINK" ]] || continue

        source=${plan_sources[i]}
        destination=${plan_destinations[i]}

        # Recheck immediately before creating to catch changes since preflight.
        state=$(installer_deployment_classify "$source" "$destination") || state=ERROR

        if [[ "$state" != "MISSING" ]]; then
            printf '[DEPLOY] ERROR: Destination changed after preflight: %s (%s)\n' \
                "$destination" "$state" >&2
            failed=1
            break
        fi

        if installer_deployment_create_link "$source" "$destination"; then
            INSTALLER_DEPLOYMENT_CREATED_PATHS+=("$destination")
            INSTALLER_DEPLOYMENT_CREATED_TARGETS+=("$source")
            printf '[DEPLOY] CREATED: %s\n' "$destination"
        else
            # The helper may have created the link before a verification error.
            if [[ -n "$INSTALLER_DEPLOYMENT_LAST_CREATED_PATH" ]]; then
                INSTALLER_DEPLOYMENT_CREATED_PATHS+=("$INSTALLER_DEPLOYMENT_LAST_CREATED_PATH")
                INSTALLER_DEPLOYMENT_CREATED_TARGETS+=("$INSTALLER_DEPLOYMENT_LAST_CREATED_TARGET")
            fi
            failed=1
            break
        fi
    done

    if (( failed )); then
        printf '[DEPLOY] Deployment failed. Starting rollback.\n' >&2
        installer_deployment_rollback || {
            printf '[DEPLOY] WARNING: Rollback was incomplete; inspect the paths reported above.\n' >&2
            return 1
        }
        return 1
    fi

    printf '[DEPLOY] Deployment completed successfully.\n'
    return 0
}
