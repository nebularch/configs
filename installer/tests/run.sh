#!/usr/bin/env bash

# HyprV Installer - Native Bash test suite.
#
# All filesystem tests run inside temporary HOME/state directories.
# No real desktop configuration is modified.

set -uo pipefail

TEST_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

INSTALLER_DIR="$(
    cd -- "$TEST_DIR/.." &&
    pwd
)"

# Load the real entry point without executing the installer.
source "$INSTALLER_DIR/main.sh"
source "$INSTALLER_DIR/deployment/executor.sh"

TEST_ROOT="$(mktemp -d)" || exit 1
trap 'rm -rf -- "$TEST_ROOT"' EXIT

TESTS_PASSED=0
TESTS_FAILED=0

new_sandbox() {
    local sandbox

    sandbox="$(mktemp -d "$TEST_ROOT/case.XXXXXX")" || return 1

    export HOME="$sandbox/home"
    export XDG_STATE_HOME="$sandbox/state"

    mkdir -p "$HOME" "$XDG_STATE_HOME" || return 1

    unset INSTALLER_BACKUP_DIR
}

assert_true() {
    if ! "$@"; then
        printf '[FAIL] Assertion failed: %s\n' "$*" >&2
        return 1
    fi
}

assert_eq() {
    local expected="$1"
    local actual="$2"

    if [[ "$expected" != "$actual" ]]; then
        printf '[FAIL] Expected: <%s>\n' "$expected" >&2
        printf '[FAIL] Actual:   <%s>\n' "$actual" >&2
        return 1
    fi
}

expect_failure() {
    if "$@" >/dev/null 2>&1; then
        printf '[FAIL] Expected command to fail: %s\n' "$*" >&2
        return 1
    fi
}

run_test() {
    local name="$1"

    printf '\n[TEST] %s\n' "$name"

    if ( "$name" ); then
        printf '[PASS] %s\n' "$name"
        ((TESTS_PASSED += 1))
    else
        printf '[FAIL] %s\n' "$name"
        ((TESTS_FAILED += 1))
    fi
}

# --------------------------------------------------
# UI tests
# --------------------------------------------------

test_prompt_yes() {
    local status

    if installer_prompt_yes_no "Test?" n <<<"y" 2>/dev/null; then
        status=0
    else
        status=$?
    fi

    assert_eq 0 "$status"
}

test_prompt_no() {
    local status

    if installer_prompt_yes_no "Test?" y <<<"n" 2>/dev/null; then
        status=0
    else
        status=$?
    fi

    assert_eq 1 "$status"
}

test_prompt_default_yes() {
    local status

    if installer_prompt_yes_no "Test?" y <<<"" 2>/dev/null; then
        status=0
    else
        status=$?
    fi

    assert_eq 0 "$status"
}

test_prompt_default_no() {
    local status

    if installer_prompt_yes_no "Test?" n <<<"" 2>/dev/null; then
        status=0
    else
        status=$?
    fi

    assert_eq 1 "$status"
}

test_prompt_invalid_then_yes() {
    local status
    local output

    output="$(
        installer_prompt_yes_no "Test?" n <<< $'maybe\ny' 2>&1
    )" && status=0 || status=$?

    assert_eq 0 "$status"
    assert_true grep -q "Please answer yes or no" <<<"$output"
}

test_prompt_eof() {
    local status

    if installer_prompt_yes_no "Test?" n </dev/null 2>/dev/null; then
        status=0
    else
        status=$?
    fi

    assert_eq 2 "$status"
}

test_option_yes() {
    installer_set_yes_no_option "Enable feature?" FEATURE <<<"y" || return 1
    assert_eq yes "$FEATURE"
}

test_option_no() {
    installer_set_yes_no_option "Enable feature?" FEATURE <<<"n" || return 1
    assert_eq no "$FEATURE"
}

test_option_eof() {
    local status

    if installer_set_yes_no_option "Enable feature?" FEATURE </dev/null 2>/dev/null; then
        status=0
    else
        status=$?
    fi

    assert_eq 2 "$status" || return 1
    assert_true test -z "${FEATURE:-}"
}

test_choose_lua() {
    installer_choose_config <<<"1" >/dev/null 2>&1 || return 1
    assert_eq lua "$REPLY"
}

test_choose_conf() {
    installer_choose_config <<<"2" >/dev/null 2>&1 || return 1
    assert_eq conf "$REPLY"
}

test_choose_invalid_then_conf() {
    installer_choose_config <<< $'invalid\n2' >/dev/null 2>&1 || return 1
    assert_eq conf "$REPLY"
}

test_choose_eof() {
    local status

    if installer_choose_config </dev/null >/dev/null 2>&1; then
        status=0
    else
        status=$?
    fi

    assert_eq 2 "$status"
}

# --------------------------------------------------
# Backup tests
# --------------------------------------------------

test_backup_file() {
    new_sandbox || return 1

    printf 'backup test content\n' > "$HOME/example.txt"

    installer_backup_path "$HOME/example.txt" >/dev/null || return 1

    assert_true test -f "$INSTALLER_BACKUP_DIR/files$HOME/example.txt" || return 1

    assert_eq \
        "backup test content" \
        "$(cat "$INSTALLER_BACKUP_DIR/files$HOME/example.txt")"
}

test_backup_directory() {
    new_sandbox || return 1

    mkdir -p "$HOME/config/nested"
    printf 'nested data\n' > "$HOME/config/nested/example"

    installer_backup_path "$HOME/config" >/dev/null || return 1

    assert_eq \
        "nested data" \
        "$(cat "$INSTALLER_BACKUP_DIR/files$HOME/config/nested/example")"
}

test_backup_symlinks() {
    new_sandbox || return 1

    printf 'target\n' > "$HOME/target"
    ln -s target "$HOME/normal-link"
    ln -s missing-target "$HOME/dangling-link"

    installer_backup_path "$HOME/normal-link" >/dev/null || return 1
    installer_backup_path "$HOME/dangling-link" >/dev/null || return 1

    assert_true test -L "$INSTALLER_BACKUP_DIR/files$HOME/normal-link" || return 1
    assert_true test -L "$INSTALLER_BACKUP_DIR/files$HOME/dangling-link" || return 1

    assert_eq target "$(readlink "$INSTALLER_BACKUP_DIR/files$HOME/normal-link")"
    assert_eq missing-target "$(readlink "$INSTALLER_BACKUP_DIR/files$HOME/dangling-link")"
}

test_backup_manifest() {
    new_sandbox || return 1

    printf 'manifest test\n' > "$HOME/file"

    installer_backup_path "$HOME/file" >/dev/null || return 1

    assert_true test -f "$INSTALLER_BACKUP_DIR/manifest.txt" || return 1
    assert_true grep -q 'SOURCE=' "$INSTALLER_BACKUP_DIR/manifest.txt"
}

test_backup_rejects_unsafe_paths() {
    new_sandbox || return 1

    local unsafe

    for unsafe in \
        relative/path \
        / \
        /tmp/../etc \
        /tmp/./example \
        /tmp//example \
        /tmp/example/
    do
        expect_failure installer_backup_path "$unsafe" || return 1
    done
}

test_backup_missing_path_is_ignored() {
    new_sandbox || return 1

    installer_backup_path "$HOME/does-not-exist" >/dev/null || return 1

    assert_true test -z "${INSTALLER_BACKUP_DIR:-}"
}

test_backup_duplicate_is_rejected() {
    new_sandbox || return 1

    printf 'original\n' > "$HOME/file"

    installer_backup_path "$HOME/file" >/dev/null || return 1

    expect_failure installer_backup_path "$HOME/file" || return 1
}

# --------------------------------------------------
# Restore tests
# --------------------------------------------------

test_restore_directory() {
    new_sandbox || return 1

    mkdir -p "$HOME/config/nested"
    printf 'restore me\n' > "$HOME/config/nested/file"

    installer_backup_path "$HOME/config" >/dev/null || return 1
    local backup_dir="$INSTALLER_BACKUP_DIR"

    rm -rf "$HOME/config"

    installer_restore_path "$backup_dir" "$HOME/config" >/dev/null || return 1

    assert_eq "restore me" "$(cat "$HOME/config/nested/file")"
}

test_restore_symlinks() {
    new_sandbox || return 1

    printf 'target\n' > "$HOME/target"
    ln -s target "$HOME/normal-link"
    ln -s absent "$HOME/dangling-link"

    installer_backup_path "$HOME/normal-link" >/dev/null || return 1
    installer_backup_path "$HOME/dangling-link" >/dev/null || return 1

    local backup_dir="$INSTALLER_BACKUP_DIR"

    rm "$HOME/normal-link" "$HOME/dangling-link"

    installer_restore_path "$backup_dir" "$HOME/normal-link" >/dev/null || return 1
    installer_restore_path "$backup_dir" "$HOME/dangling-link" >/dev/null || return 1

    assert_true test -L "$HOME/normal-link" || return 1
    assert_true test -L "$HOME/dangling-link" || return 1

    assert_eq target "$(readlink "$HOME/normal-link")"
    assert_eq absent "$(readlink "$HOME/dangling-link")"
}

test_restore_preserves_existing_destination() {
    new_sandbox || return 1

    printf 'backup version\n' > "$HOME/file"

    installer_backup_path "$HOME/file" >/dev/null || return 1
    local backup_dir="$INSTALLER_BACKUP_DIR"

    printf 'current version\n' > "$HOME/file"

    expect_failure installer_restore_path "$backup_dir" "$HOME/file" || return 1

    assert_eq "current version" "$(cat "$HOME/file")"
}

test_restore_rejects_unsafe_paths() {
    new_sandbox || return 1

    printf 'test\n' > "$HOME/file"
    installer_backup_path "$HOME/file" >/dev/null || return 1

    local backup_dir="$INSTALLER_BACKUP_DIR"
    local unsafe

    for unsafe in \
        relative/path \
        / \
        /tmp/../etc \
        /tmp/./example \
        /tmp//example \
        /tmp/example/
    do
        expect_failure installer_restore_path "$backup_dir" "$unsafe" || return 1
    done
}

test_restore_rejects_external_session() {
    new_sandbox || return 1

    local forged="$TEST_ROOT/outside/backup-forged"

    mkdir -p "$forged/files$HOME"
    touch "$forged/manifest.txt"
    printf 'forged data\n' > "$forged/files$HOME/file"

    expect_failure installer_restore_path "$forged" "$HOME/file"
}

test_restore_rejects_session_symlink() {
    new_sandbox || return 1

    printf 'test\n' > "$HOME/file"
    installer_backup_path "$HOME/file" >/dev/null || return 1

    local backup_dir="$INSTALLER_BACKUP_DIR"
    local link="$TEST_ROOT/backup-link"

    ln -s "$backup_dir" "$link" || return 1

    expect_failure installer_restore_path "$link" "$HOME/file"
}


# --------------------------------------------------
# Package planning tests
# --------------------------------------------------

test_package_collection_deduplicates_and_includes_options() {
    installer_load_package_manifest || return 1

    HYPRV_BASE_PACKAGES=(alpha shared)
    HYPRV_DESKTOP_PACKAGES=(beta shared)
    HYPRV_STARSHIP_PACKAGES=(starship)
    HYPRV_ROG_PACKAGES=(rog-tool)

    installer_collect_packages yes yes >/dev/null || return 1

    assert_eq 5 "${#INSTALLER_REQUESTED_PACKAGES[@]}" || return 1
    assert_eq 'alpha shared beta starship rog-tool' "${INSTALLER_REQUESTED_PACKAGES[*]}"
}


test_package_classification_separates_sources() {
    INSTALLER_REQUESTED_PACKAGES=(
        installed-test official-test official-via-yay-test aur-test other-test missing-test
    )

    pacman-conf() {
        printf 'core\nextra\nmultilib\n'
    }

    pacman() {
        case "$1:$2" in
            -Qq:installed-test) return 0 ;;
            -Qq:*) return 1 ;;
            -Si:official-test) return 0 ;;
            -Si:*)
                printf "error: package '%s' was not found in sync db\n" "$2"
                return 1
                ;;
            *) return 1 ;;
        esac
    }

    yay() {
        case "$1:$2" in
            -Si:official-via-yay-test) printf 'Repository : extra\n' ;;
            -Si:aur-test) printf 'Repository : aur\n' ;;
            -Si:other-test) printf 'Repository : custom-repo\n' ;;
            -Si:missing-test)
                printf ' -> No AUR package found for missing-test\n'
                return 1
                ;;
            *) return 1 ;;
        esac
    }

    installer_classify_packages >/dev/null || return 1

    assert_eq 'installed-test' "${INSTALLER_INSTALLED_PACKAGES[*]}" || return 1
    assert_eq 'official-test official-via-yay-test' "${INSTALLER_SYNC_PACKAGES[*]}" || return 1
    assert_eq 'aur-test' "${INSTALLER_AUR_PACKAGES[*]}" || return 1
    assert_eq 'other-test' "${INSTALLER_OTHER_PACKAGES[*]}" || return 1
    assert_eq 'missing-test' "${INSTALLER_UNAVAILABLE_PACKAGES[*]}" || return 1
    assert_eq 0 "${#INSTALLER_UNVERIFIED_PACKAGES[@]}"
}

test_package_plan_rejects_unavailable_package() {
    installer_load_package_manifest || return 1
    HYPRV_BASE_PACKAGES=(missing-test)
    HYPRV_DESKTOP_PACKAGES=()
    HYPRV_STARSHIP_PACKAGES=()
    HYPRV_ROG_PACKAGES=()

    pacman() {
        if [[ "$1" == "-Qq" ]]; then
            return 1
        fi
        printf "error: package '%s' was not found in sync db
" "$2"
        return 1
    }

    yay() {
        printf " -> No AUR package found for %s
" "$2"
        return 1
    }

    local status
    if installer_prepare_package_plan no no >/dev/null 2>&1; then
        status=0
    else
        status=$?
    fi

    assert_eq 1 "$status" || return 1
    assert_eq "missing-test" "${INSTALLER_UNAVAILABLE_PACKAGES[*]}"
}

test_package_plan_accepts_all_installed() {
    installer_load_package_manifest || return 1

    HYPRV_BASE_PACKAGES=(already-installed)
    HYPRV_DESKTOP_PACKAGES=()
    HYPRV_STARSHIP_PACKAGES=()
    HYPRV_ROG_PACKAGES=()

    pacman() {
        case "$1:$2" in
            -Qq:already-installed) return 0 ;;
            *) return 1 ;;
        esac
    }

    yay() { return 1; }

    local status
    if installer_prepare_package_plan no no >/dev/null 2>&1; then
        status=0
    else
        status=$?
    fi

    assert_eq 0 "$status"
}


test_package_plan_rejects_other_repository() {
    installer_load_package_manifest || return 1
    HYPRV_BASE_PACKAGES=(custom-repo-test)
    HYPRV_DESKTOP_PACKAGES=()
    HYPRV_STARSHIP_PACKAGES=()
    HYPRV_ROG_PACKAGES=()

    pacman-conf() {
        printf 'core\nextra\nmultilib\n'
    }

    pacman() {
        if [[ "$1" == "-Qq" ]]; then
            return 1
        fi
        printf "error: package '%s' was not found in sync db\n" "$2"
        return 1
    }

    yay() {
        printf 'Repository : custom-repo\n'
    }

    local status
    if installer_prepare_package_plan no no >/dev/null 2>&1; then
        status=0
    else
        status=$?
    fi

    assert_eq 2 "$status" || return 1
    assert_eq 'custom-repo-test' "${INSTALLER_OTHER_PACKAGES[*]}"
}

test_package_plan_rejects_empty_request() {
    installer_load_package_manifest || return 1

    HYPRV_BASE_PACKAGES=()
    HYPRV_DESKTOP_PACKAGES=()
    HYPRV_STARSHIP_PACKAGES=()
    HYPRV_ROG_PACKAGES=()

    local status
    if installer_prepare_package_plan no no >/dev/null 2>&1; then
        status=0
    else
        status=$?
    fi

    assert_eq 2 "$status"
}


test_package_plan_marks_repository_list_failure_unverified() {
    installer_load_package_manifest || return 1
    HYPRV_BASE_PACKAGES=(official-repo-test)
    HYPRV_DESKTOP_PACKAGES=()
    HYPRV_STARSHIP_PACKAGES=()
    HYPRV_ROG_PACKAGES=()

    pacman-conf() {
        printf 'unable to read pacman configuration\n' >&2
        return 1
    }

    pacman() {
        if [[ "$1" == "-Qq" ]]; then
            return 1
        fi
        printf "error: package '%s' was not found in sync db\n" "$2"
        return 1
    }

    yay() {
        printf 'Repository : extra\n'
    }

    local status
    if installer_prepare_package_plan no no >/dev/null 2>&1; then
        status=0
    else
        status=$?
    fi

    assert_eq 3 "$status" || return 1
    assert_eq 'official-repo-test' "${INSTALLER_UNVERIFIED_PACKAGES[*]}" || return 1
    assert_eq 0 "${#INSTALLER_OTHER_PACKAGES[@]}"
}


# --------------------------------------------------
# Installer orchestration tests
# --------------------------------------------------

test_main_runs_package_plan_before_summary_and_confirmation() {
    TEST_FLOW=""
    TEST_PLAN_STATUS=0

    installer_init_logging() { INSTALLER_LOG="test.log"; }
    installer_preflight() { :; }
    installer_choose_config() { REPLY="lua"; }

    installer_strategy_plan() {
        TEST_FLOW+="T"
        return 0
    }

    installer_deployment_plan() {
        TEST_FLOW+="D"
        return 0
    }

    installer_set_yes_no_option() {
        printf -v "$2" '%s' "no"
    }

    installer_prepare_package_plan() {
        TEST_FLOW+="P"
        return "$TEST_PLAN_STATUS"
    }

    installer_summary() {
        TEST_FLOW+="S"
    }

    installer_prompt_yes_no() {
        TEST_FLOW+="C"
        return 0
    }

    installer_main >/dev/null || return 1

    assert_eq "TDPSC" "$TEST_FLOW"
}

test_main_stops_when_deployment_plan_is_not_ready() {
    TEST_FLOW=""

    installer_init_logging() { INSTALLER_LOG="test.log"; }
    installer_preflight() { :; }
    installer_choose_config() { REPLY="lua"; }

    installer_strategy_plan() {
        TEST_FLOW+="T"
        return 0
    }

    installer_deployment_plan() {
        TEST_FLOW+="D"
        return 1
    }

    installer_set_yes_no_option() {
        printf -v "$2" '%s' "no"
    }

    installer_prepare_package_plan() {
        TEST_FLOW+="P"
        return 0
    }

    local status
    if installer_main >/dev/null 2>&1; then
        status=0
    else
        status=$?
    fi

    assert_eq 1 "$status" || return 1
    assert_eq "TD" "$TEST_FLOW"
}

test_main_stops_when_package_plan_is_not_ready() {
    TEST_FLOW=""
    TEST_PLAN_STATUS=3

    installer_init_logging() { INSTALLER_LOG="test.log"; }
    installer_preflight() { :; }
    installer_choose_config() { REPLY="lua"; }

    installer_strategy_plan() {
        TEST_FLOW+="T"
        return 0
    }

    installer_deployment_plan() {
        TEST_FLOW+="D"
        return 0
    }

    installer_set_yes_no_option() {
        printf -v "$2" '%s' "no"
    }

    installer_prepare_package_plan() {
        TEST_FLOW+="P"
        return "$TEST_PLAN_STATUS"
    }

    installer_summary() {
        TEST_FLOW+="S"
    }

    installer_prompt_yes_no() {
        TEST_FLOW+="C"
        return 0
    }

    local status
    if installer_main >/dev/null 2>&1; then
        status=0
    else
        status=$?
    fi

    assert_eq 1 "$status" || return 1
    assert_eq "TDP" "$TEST_FLOW"
}

# --------------------------------------------------
# Run suite
# --------------------------------------------------

printf '\n============================================\n'
printf '       HYPRV INSTALLER TEST SUITE\n'
printf '============================================\n'

test_package_plan_marks_lookup_failures_unverified() {
    installer_load_package_manifest || return 1
    HYPRV_BASE_PACKAGES=(network-failure-test)
    HYPRV_DESKTOP_PACKAGES=()
    HYPRV_STARSHIP_PACKAGES=()
    HYPRV_ROG_PACKAGES=()

    pacman() {
        if [[ "$1" == "-Qq" ]]; then
            return 1
        fi
        printf 'error: failed retrieving file from mirror\n'
        return 1
    }

    yay() {
        printf 'error: network unreachable\n'
        return 1
    }

    local status
    if installer_prepare_package_plan no no >/dev/null 2>&1; then
        status=0
    else
        status=$?
    fi

    assert_eq 3 "$status" || return 1
    assert_eq "network-failure-test" "${INSTALLER_UNVERIFIED_PACKAGES[*]}" || return 1
    assert_eq 0 "${#INSTALLER_UNAVAILABLE_PACKAGES[@]}"
}


# --------------------------------------------------
# Configuration strategy tests
# --------------------------------------------------

strategy_make_lua_fixture() {
    local root="$1"
    local file

    local -a files=(
        HyprV/hypr/hyprland.lua
        HyprV/hypr/lua/init.lua
        HyprV/hypr/lua/settings.lua
        HyprV/hypr/lua/environment.lua
        HyprV/hypr/lua/monitors.lua
        HyprV/hypr/lua/input.lua
        HyprV/hypr/lua/animations.lua
        HyprV/hypr/lua/layouts.lua
        HyprV/hypr/lua/windowrules.lua
        HyprV/hypr/lua/gestures.lua
        HyprV/hypr/lua/keybinds.lua
        HyprV/hypr/lua/media.lua
        HyprV/hypr/lua/autostart.lua
    )

    for file in "${files[@]}"; do
        mkdir -p "$root/$(dirname "$file")"
        : > "$root/$file"
    done
}

strategy_make_conf_fixture() {
    local root="$1"
    local file

    local -a files=(
        HyprV/hypr/hyprland.conf
        HyprV/hypr/env_var.conf
        HyprV/hypr/media-binds.conf
        HyprV/hyprv_util
        HyprV/hypr/xdg-portal-hyprland
    )

    for file in "${files[@]}"; do
        mkdir -p "$root/$(dirname "$file")"
        : > "$root/$file"
    done
}

test_lua_strategy_validates_repository() {
    INSTALLER_CONFIG_MODE=lua
    INSTALLER_ENABLE_NVIDIA=no
    INSTALLER_ENABLE_ROG=no

    installer_strategy_validate >/dev/null || return 1
    assert_eq "Lua" "$INSTALLER_STRATEGY_LABEL"
}

test_lua_strategy_rejects_missing_module() {
    local original_root="$REPO_ROOT"
    REPO_ROOT="$TEST_ROOT/lua-missing"

    strategy_make_lua_fixture "$REPO_ROOT"
    rm -f "$REPO_ROOT/HyprV/hypr/lua/gestures.lua"

    INSTALLER_CONFIG_MODE=lua
    INSTALLER_ENABLE_NVIDIA=no
    INSTALLER_ENABLE_ROG=no

    if installer_strategy_validate >/dev/null 2>&1; then
        REPO_ROOT="$original_root"
        return 1
    fi

    REPO_ROOT="$original_root"
    return 0
}

test_lua_strategy_requires_selected_nvidia_module() {
    local original_root="$REPO_ROOT"
    REPO_ROOT="$TEST_ROOT/lua-nvidia"

    strategy_make_lua_fixture "$REPO_ROOT"

    INSTALLER_CONFIG_MODE=lua
    INSTALLER_ENABLE_NVIDIA=yes
    INSTALLER_ENABLE_ROG=no

    if installer_strategy_validate >/dev/null 2>&1; then
        REPO_ROOT="$original_root"
        return 1
    fi

    REPO_ROOT="$original_root"
    return 0
}

test_conf_strategy_validates_repository() {
    INSTALLER_CONFIG_MODE=conf
    INSTALLER_ENABLE_NVIDIA=no
    INSTALLER_ENABLE_ROG=no

    installer_strategy_validate >/dev/null || return 1
    assert_eq "CONF" "$INSTALLER_STRATEGY_LABEL"
}

test_conf_strategy_rejects_missing_helper() {
    local original_root="$REPO_ROOT"
    REPO_ROOT="$TEST_ROOT/conf-missing"

    strategy_make_conf_fixture "$REPO_ROOT"
    rm -f "$REPO_ROOT/HyprV/hyprv_util"

    INSTALLER_CONFIG_MODE=conf
    INSTALLER_ENABLE_NVIDIA=no
    INSTALLER_ENABLE_ROG=no

    if installer_strategy_validate >/dev/null 2>&1; then
        REPO_ROOT="$original_root"
        return 1
    fi

    REPO_ROOT="$original_root"
    return 0
}

test_conf_strategy_requires_selected_rog_file() {
    local original_root="$REPO_ROOT"
    REPO_ROOT="$TEST_ROOT/conf-rog"

    strategy_make_conf_fixture "$REPO_ROOT"

    INSTALLER_CONFIG_MODE=conf
    INSTALLER_ENABLE_NVIDIA=no
    INSTALLER_ENABLE_ROG=yes

    if installer_strategy_validate >/dev/null 2>&1; then
        REPO_ROOT="$original_root"
        return 1
    fi

    REPO_ROOT="$original_root"
    return 0
}

test_strategy_dispatch_rejects_unknown_mode() {
    INSTALLER_CONFIG_MODE=unknown

    if installer_strategy_validate >/dev/null 2>&1; then
        return 1
    fi

    return 0
}

test_strategy_plan_reports_selected_mode() {
    INSTALLER_CONFIG_MODE=lua
    INSTALLER_ENABLE_NVIDIA=no
    INSTALLER_ENABLE_ROG=no

    local output
    output="$(installer_strategy_plan)" || return 1

    assert_true grep -q "Configuration strategy: Lua" <<<"$output" ||
        return 1
    assert_true grep -q "Private settings: preserved" <<<"$output"
}


# --------------------------------------------------
# Deployment planner tests
# --------------------------------------------------

test_deployment_manifest_contains_lua_mappings() {
    local original_root="$REPO_ROOT"
    local sandbox_root="$TEST_ROOT/deployment-manifest"

    mkdir -p "$sandbox_root/HyprV/hypr/lua"
    touch "$sandbox_root/HyprV/hypr/hyprland.lua"

    REPO_ROOT="$sandbox_root"
    INSTALLER_CONFIG_MODE=lua

    installer_load_deployment_manifest || return 1

    REPO_ROOT="$original_root"

    assert_eq 2 "${#INSTALLER_DEPLOYMENT_IDS[@]}" || return 1
    assert_eq "hyprland-entrypoint" "${INSTALLER_DEPLOYMENT_IDS[0]}" ||
        return 1
    assert_eq "lua-modules" "${INSTALLER_DEPLOYMENT_IDS[1]}"
}

test_deployment_classifies_missing_destination() {
    new_sandbox || return 1

    local source="$TEST_ROOT/deployment-source"
    touch "$source"

    local status
    status="$(installer_deployment_classify "$source" "$HOME/missing")" ||
        return 1

    assert_eq "MISSING" "$status"
}

test_deployment_classifies_matching_symlink() {
    new_sandbox || return 1

    local source="$TEST_ROOT/deployment-source"
    local destination="$HOME/deployment-link"

    touch "$source"
    ln -s "$source" "$destination"

    local status
    status="$(installer_deployment_classify "$source" "$destination")" ||
        return 1

    assert_eq "MATCH" "$status"
}

test_deployment_classifies_identical_file() {
    new_sandbox || return 1

    local source="$TEST_ROOT/deployment-source"
    local destination="$HOME/deployment-copy"

    printf 'same content\n' > "$source"
    cp "$source" "$destination"

    local status
    status="$(installer_deployment_classify "$source" "$destination")" ||
        return 1

    assert_eq "IDENTICAL" "$status"
}

test_deployment_classifies_conflicting_file() {
    new_sandbox || return 1

    local source="$TEST_ROOT/deployment-source"
    local destination="$HOME/deployment-copy"

    printf 'repository version\n' > "$source"
    printf 'user version\n' > "$destination"

    local status
    status="$(installer_deployment_classify "$source" "$destination")" ||
        return 1

    assert_eq "CONFLICT" "$status"
}

test_deployment_classifies_dangling_symlink_as_conflict() {
    new_sandbox || return 1

    local source="$TEST_ROOT/deployment-source"
    local destination="$HOME/deployment-link"

    touch "$source"
    ln -s "$HOME/nonexistent-target" "$destination"

    local status
    status="$(installer_deployment_classify "$source" "$destination")" ||
        return 1

    assert_eq "CONFLICT" "$status"
}

test_deployment_rejects_symlinked_parent() {
    new_sandbox || return 1

    local source="$TEST_ROOT/deployment-source"
    local real_parent="$HOME/real-parent"
    local linked_parent="$HOME/linked-parent"

    touch "$source"
    mkdir -p "$real_parent"
    ln -s "$real_parent" "$linked_parent"

    local status
    status="$(
        installer_deployment_classify \
            "$source" "$linked_parent/destination"
    )" || return 1

    assert_eq "CONFLICT" "$status"
}

test_deployment_rejects_non_directory_parent() {
    new_sandbox || return 1

    local source="$TEST_ROOT/deployment-source"
    local parent="$HOME/not-a-directory"

    touch "$source"
    touch "$parent"

    local status
    status="$(
        installer_deployment_classify "$source" "$parent/destination"
    )" || return 1

    assert_eq "CONFLICT" "$status"
}

test_deployment_rejects_relative_destination() {
    new_sandbox || return 1

    local source="$TEST_ROOT/deployment-source"
    touch "$source"

    local status
    status="$(
        installer_deployment_classify "$source" "relative/destination"
    )" || return 1

    assert_eq "CONFLICT" "$status"
}

test_deployment_rejects_newline_destination() {
    new_sandbox || return 1

    local source="$TEST_ROOT/deployment-source"
    local destination="$TEST_ROOT/line"$'\n'"break"
    touch "$source"

    local status
    status="$(
        installer_deployment_classify "$source" "$destination"
    )" || return 1

    assert_eq "CONFLICT" "$status"
}

test_deployment_rejects_carriage_return_destination() {
    new_sandbox || return 1

    local source="$TEST_ROOT/deployment-source"
    local destination="$TEST_ROOT/carriage"$'\r'"return"
    touch "$source"

    local status
    status="$(
        installer_deployment_classify "$source" "$destination"
    )" || return 1

    assert_eq "CONFLICT" "$status"
}

test_deployment_dry_run_does_not_create_destinations() {
    new_sandbox || return 1

    local original_root="$REPO_ROOT"
    local sandbox_root="$TEST_ROOT/deployment-read-only"
    local entrypoint="$sandbox_root/HyprV/hypr/hyprland.lua"
    local modules="$sandbox_root/HyprV/hypr/lua"
    local entrypoint_destination="$HOME/.config/hypr/hyprland.lua"
    local modules_destination="$HOME/.config/hypr/hyprv"

    mkdir -p "$modules"
    touch "$entrypoint"

    REPO_ROOT="$sandbox_root"
    INSTALLER_CONFIG_MODE=lua

    installer_deployment_plan >/dev/null || {
        REPO_ROOT="$original_root"
        return 1
    }

    REPO_ROOT="$original_root"

    [[ ! -e "$entrypoint_destination" &&
       ! -L "$entrypoint_destination" ]] || return 1

    [[ ! -e "$modules_destination" &&
       ! -L "$modules_destination" ]] || return 1
}

test_deployment_rejects_missing_source() {
    new_sandbox || return 1

    expect_failure installer_deployment_classify \
        "$TEST_ROOT/nonexistent-source" "$HOME/destination"
}

test_deployment_defers_conf_strategy() {
    INSTALLER_CONFIG_MODE=conf

    local output
    output="$(installer_deployment_plan)" || return 1

    assert_true grep -q "CONF deployment mappings are not defined" \
        <<<"$output"
}


# --------------------------------------------------
# Deployment executor tests
# --------------------------------------------------

setup_executor_fixture() {
    new_sandbox || return 1

    EXECUTOR_REPO="$TEST_ROOT/executor-repo"
    EXECUTOR_SOURCE_ONE="HyprV/hypr/hyprland.lua"
    EXECUTOR_SOURCE_TWO="HyprV/hypr/lua/init.lua"
    EXECUTOR_DEST_ONE="$HOME/.config/hypr/hyprland.lua"
    EXECUTOR_DEST_TWO="$HOME/.config/hypr/hyprv"

    mkdir -p "$EXECUTOR_REPO/HyprV/hypr/lua" \
        "$HOME/.config/hypr" || return 1

    printf 'sandbox entrypoint\n' \
        > "$EXECUTOR_REPO/$EXECUTOR_SOURCE_ONE"
    printf 'sandbox module\n' \
        > "$EXECUTOR_REPO/$EXECUTOR_SOURCE_TWO"

    REPO_ROOT="$EXECUTOR_REPO"
    INSTALLER_CONFIG_MODE=lua

    installer_load_deployment_manifest() {
        INSTALLER_DEPLOYMENT_IDS=(entrypoint modules)
        INSTALLER_DEPLOYMENT_SOURCES=(
            "$EXECUTOR_SOURCE_ONE"
            "$EXECUTOR_SOURCE_TWO"
        )
        INSTALLER_DEPLOYMENT_DESTINATIONS=(
            "$EXECUTOR_DEST_ONE"
            "$EXECUTOR_DEST_TWO"
        )
        INSTALLER_DEPLOYMENT_LABELS=("Entrypoint" "Lua modules")
    }
}

test_deployment_executor_creates_missing_symlinks() {
    setup_executor_fixture || return 1

    installer_deployment_execute || return 1

    assert_true test -L "$EXECUTOR_DEST_ONE" || return 1
    assert_true test -L "$EXECUTOR_DEST_TWO" || return 1

    assert_eq \
        "$EXECUTOR_REPO/$EXECUTOR_SOURCE_ONE" \
        "$(readlink -- "$EXECUTOR_DEST_ONE")" || return 1

    assert_eq \
        "$EXECUTOR_REPO/$EXECUTOR_SOURCE_TWO" \
        "$(readlink -- "$EXECUTOR_DEST_TWO")"
}

test_deployment_executor_skips_matching_symlink() {
    setup_executor_fixture || return 1

    ln -s "$EXECUTOR_REPO/$EXECUTOR_SOURCE_ONE" \
        "$EXECUTOR_DEST_ONE"

    installer_deployment_execute || return 1

    assert_true test -L "$EXECUTOR_DEST_ONE" || return 1
    assert_true test -L "$EXECUTOR_DEST_TWO"
}

test_deployment_executor_preserves_identical_file() {
    setup_executor_fixture || return 1

    cp "$EXECUTOR_REPO/$EXECUTOR_SOURCE_ONE" "$EXECUTOR_DEST_ONE"

    local before
    before=$(sha256sum "$EXECUTOR_DEST_ONE") || return 1

    installer_deployment_execute || return 1

    local after
    after=$(sha256sum "$EXECUTOR_DEST_ONE") || return 1

    assert_eq "$before" "$after" || return 1
    assert_true test ! -L "$EXECUTOR_DEST_ONE" || return 1
    assert_true test -L "$EXECUTOR_DEST_TWO"
}

test_deployment_executor_blocks_conflict_before_changes() {
    setup_executor_fixture || return 1

    printf 'user-owned content\n' > "$EXECUTOR_DEST_TWO"

    expect_failure installer_deployment_execute || return 1

    assert_true test ! -e "$EXECUTOR_DEST_ONE" || return 1
    assert_true test ! -L "$EXECUTOR_DEST_ONE" || return 1
    assert_eq "user-owned content" "$(cat "$EXECUTOR_DEST_TWO")"
}

test_deployment_executor_rejects_duplicate_destinations() {
    setup_executor_fixture || return 1

    installer_load_deployment_manifest() {
        INSTALLER_DEPLOYMENT_IDS=(first second)
        INSTALLER_DEPLOYMENT_SOURCES=(
            "$EXECUTOR_SOURCE_ONE"
            "$EXECUTOR_SOURCE_TWO"
        )
        INSTALLER_DEPLOYMENT_DESTINATIONS=(
            "$EXECUTOR_DEST_ONE"
            "$EXECUTOR_DEST_ONE"
        )
        INSTALLER_DEPLOYMENT_LABELS=("First" "Second")
    }

    expect_failure installer_deployment_execute || return 1

    assert_true test ! -e "$EXECUTOR_DEST_ONE" || return 1
    assert_true test ! -L "$EXECUTOR_DEST_ONE"
}

test_deployment_executor_rolls_back_when_stage_cleanup_fails() {
    setup_executor_fixture || return 1

    local output="$TEST_ROOT/stage-cleanup-failure.log"
    local status

    TEST_STAGE_CLEANUP_PATH=""

    # Inject a cleanup failure while recording the staging directory.
    installer_deployment_cleanup_stage() {
        TEST_STAGE_CLEANUP_PATH=$1
        printf '[TEST] Injected staging cleanup failure.\n' >&2
        return 1
    }

    if installer_deployment_execute > /dev/null 2>"$output"; then
        status=0
    else
        status=$?
    fi

    assert_eq 1 "$status" || return 1
    assert_true grep -Fq \
        '[DEPLOY] WARNING: Could not clean staging directory:' \
        "$output" || return 1

    # The newly created destination must have been rolled back.
    assert_true test ! -e "$EXECUTOR_DEST_ONE" || return 1
    assert_true test ! -L "$EXECUTOR_DEST_ONE" || return 1

    # The failed cleanup must leave an identifiable staging directory.
    assert_true test -n "$TEST_STAGE_CLEANUP_PATH" || return 1
    assert_true test -d "$TEST_STAGE_CLEANUP_PATH" || return 1
    assert_eq 0 "$(find "$TEST_STAGE_CLEANUP_PATH" -mindepth 1 -maxdepth 1 | wc -l)" || return 1

    # Rollback should have cleared its tracking records.
    assert_eq 0 "${#INSTALLER_DEPLOYMENT_CREATED_PATHS[@]}" || return 1
    assert_eq 0 "${#INSTALLER_DEPLOYMENT_CREATED_TARGETS[@]}" || return 1

    # Remove only the empty test staging directory.
    rmdir -- "$TEST_STAGE_CLEANUP_PATH" || return 1
    unset TEST_STAGE_CLEANUP_PATH
}

test_deployment_executor_rolls_back_after_failure() {
    setup_executor_fixture || return 1

    # Keep the real helper and inject a failure on the second call.
    eval "$(
        declare -f installer_deployment_create_link |
        sed '1s/installer_deployment_create_link/installer_deployment_create_link_original/'
    )" || return 1

    local attempts=0

    installer_deployment_create_link() {
        ((attempts += 1))

        if (( attempts == 2 )); then
            INSTALLER_DEPLOYMENT_LAST_CREATED_PATH=""
            INSTALLER_DEPLOYMENT_LAST_CREATED_TARGET=""
            printf '[TEST] Injected second-link failure.\n' >&2
            return 1
        fi

        installer_deployment_create_link_original "$@"
    }

    expect_failure installer_deployment_execute || return 1

    assert_true test ! -e "$EXECUTOR_DEST_ONE" || return 1
    assert_true test ! -L "$EXECUTOR_DEST_ONE" || return 1
    assert_true test ! -e "$EXECUTOR_DEST_TWO" || return 1
    assert_true test ! -L "$EXECUTOR_DEST_TWO" || return 1

    assert_eq 0 "${#INSTALLER_DEPLOYMENT_CREATED_PATHS[@]}"
}

test_deployment_rollback_preserves_changed_symlink() {
    new_sandbox || return 1

    local original="$HOME/original-target"
    local replacement="$HOME/replacement-target"
    local destination="$HOME/deployment-link"

    touch "$original" "$replacement" || return 1
    ln -s "$replacement" "$destination" || return 1

    INSTALLER_DEPLOYMENT_CREATED_PATHS=("$destination")
    INSTALLER_DEPLOYMENT_CREATED_TARGETS=("$original")

    expect_failure installer_deployment_rollback || return 1

    assert_true test -L "$destination" || return 1
    assert_eq "$replacement" "$(readlink -- "$destination")" || return 1
    assert_eq 1 "${#INSTALLER_DEPLOYMENT_CREATED_PATHS[@]}" || return 1

    # Restore the expected target and retry rollback.
    ln -sfn -- "$original" "$destination" || return 1

    installer_deployment_rollback || return 1

    assert_true test ! -e "$destination" || return 1
    assert_true test ! -L "$destination" || return 1
    assert_eq 0 "${#INSTALLER_DEPLOYMENT_CREATED_PATHS[@]}"
}

test_deployment_executor_rejects_missing_repo_root() {
    setup_executor_fixture || return 1

    unset REPO_ROOT

    local status
    if installer_deployment_execute >/dev/null 2>&1; then
        status=0
    else
        status=$?
    fi

    assert_eq 1 "$status" || return 1
    assert_true test ! -e "$EXECUTOR_DEST_ONE" || return 1
    assert_true test ! -L "$EXECUTOR_DEST_ONE" || return 1
    assert_true test ! -e "$EXECUTOR_DEST_TWO" || return 1
    assert_true test ! -L "$EXECUTOR_DEST_TWO"
}

test_deployment_executor_preserves_unresolved_rollback_records() {
    setup_executor_fixture || return 1

    local pending="$HOME/pending-deployment-link"
    local expected="$HOME/expected-deployment-target"

    touch "$expected" || return 1
    ln -s "$expected" "$pending" || return 1

    INSTALLER_DEPLOYMENT_CREATED_PATHS=("$pending")
    INSTALLER_DEPLOYMENT_CREATED_TARGETS=("$expected")

    expect_failure installer_deployment_execute || return 1

    assert_true test -L "$pending" || return 1
    assert_eq "$expected" "$(readlink -- "$pending")" || return 1
    assert_eq 1 "${#INSTALLER_DEPLOYMENT_CREATED_PATHS[@]}" || return 1
    assert_eq 1 "${#INSTALLER_DEPLOYMENT_CREATED_TARGETS[@]}" || return 1
    assert_eq "$pending" "${INSTALLER_DEPLOYMENT_CREATED_PATHS[0]}" || return 1
    assert_eq "$expected" "${INSTALLER_DEPLOYMENT_CREATED_TARGETS[0]}" || return 1

    assert_true test ! -e "$EXECUTOR_DEST_ONE" || return 1
    assert_true test ! -L "$EXECUTOR_DEST_ONE"
}

test_deployment_rollback_rejects_mismatched_tracking_arrays() {
    new_sandbox || return 1

    local destination="$HOME/protected-link"
    local expected="$HOME/original-target"
    local output="$TEST_ROOT/rollback-mismatch.log"
    local status

    touch "$expected" || return 1
    ln -s "$expected" "$destination" || return 1

    INSTALLER_DEPLOYMENT_CREATED_PATHS=("$destination")
    INSTALLER_DEPLOYMENT_CREATED_TARGETS=()

    if installer_deployment_rollback > /dev/null 2>"$output"; then
        status=0
    else
        status=$?
    fi

    assert_eq 1 "$status" || return 1
    assert_true grep -Fq \
        '[ROLLBACK] ERROR: Tracking arrays have inconsistent lengths.' \
        "$output" || return 1

    # The inconsistent records must remain untouched for inspection.
    assert_eq 1 "${#INSTALLER_DEPLOYMENT_CREATED_PATHS[@]}" || return 1
    assert_eq 0 "${#INSTALLER_DEPLOYMENT_CREATED_TARGETS[@]}" || return 1
    assert_eq "$destination" "${INSTALLER_DEPLOYMENT_CREATED_PATHS[0]}" || return 1

    # Rollback must not touch filesystem paths when tracking is invalid.
    assert_true test -L "$destination" || return 1
    assert_eq "$expected" "$(readlink -- "$destination")"
}

test_deployment_rollback_accepts_already_absent_link() {
    new_sandbox || return 1

    local destination="$HOME/already-removed-link"
    local expected="$HOME/original-target"

    touch "$expected" || return 1

    INSTALLER_DEPLOYMENT_CREATED_PATHS=("$destination")
    INSTALLER_DEPLOYMENT_CREATED_TARGETS=("$expected")

    installer_deployment_rollback || return 1

    assert_eq 0 "${#INSTALLER_DEPLOYMENT_CREATED_PATHS[@]}" || return 1
    assert_eq 0 "${#INSTALLER_DEPLOYMENT_CREATED_TARGETS[@]}" || return 1
    assert_true test ! -e "$destination" || return 1
    assert_true test ! -L "$destination"
}

test_deployment_executor_defers_conf_without_changes() {
    setup_executor_fixture || return 1

    INSTALLER_CONFIG_MODE=conf

    installer_load_deployment_manifest() {
        INSTALLER_DEPLOYMENT_IDS=()
        INSTALLER_DEPLOYMENT_SOURCES=()
        INSTALLER_DEPLOYMENT_DESTINATIONS=()
        INSTALLER_DEPLOYMENT_LABELS=()
    }

    installer_deployment_execute || return 1

    assert_true test ! -e "$EXECUTOR_DEST_ONE" || return 1
    assert_true test ! -L "$EXECUTOR_DEST_ONE"
}

run_test test_deployment_executor_creates_missing_symlinks
run_test test_deployment_executor_skips_matching_symlink
run_test test_deployment_executor_preserves_identical_file
run_test test_deployment_executor_blocks_conflict_before_changes
run_test test_deployment_executor_rejects_duplicate_destinations
run_test test_deployment_executor_rolls_back_when_stage_cleanup_fails
run_test test_deployment_executor_rolls_back_after_failure
run_test test_deployment_rollback_preserves_changed_symlink
run_test test_deployment_executor_defers_conf_without_changes
run_test test_deployment_executor_rejects_missing_repo_root
run_test test_deployment_executor_preserves_unresolved_rollback_records
run_test test_deployment_rollback_rejects_mismatched_tracking_arrays
run_test test_deployment_rollback_accepts_already_absent_link

run_test test_deployment_manifest_contains_lua_mappings
run_test test_deployment_classifies_missing_destination
run_test test_deployment_classifies_matching_symlink
run_test test_deployment_classifies_identical_file
run_test test_deployment_classifies_conflicting_file
run_test test_deployment_classifies_dangling_symlink_as_conflict
run_test test_deployment_rejects_symlinked_parent
run_test test_deployment_rejects_non_directory_parent
run_test test_deployment_rejects_relative_destination
run_test test_deployment_rejects_newline_destination
run_test test_deployment_rejects_carriage_return_destination
run_test test_deployment_dry_run_does_not_create_destinations
run_test test_deployment_rejects_missing_source
run_test test_deployment_defers_conf_strategy

run_test test_lua_strategy_validates_repository
run_test test_lua_strategy_rejects_missing_module
run_test test_lua_strategy_requires_selected_nvidia_module
run_test test_conf_strategy_validates_repository
run_test test_conf_strategy_rejects_missing_helper
run_test test_conf_strategy_requires_selected_rog_file
run_test test_strategy_dispatch_rejects_unknown_mode
run_test test_strategy_plan_reports_selected_mode


test_main_stops_when_strategy_is_not_ready() {
    TEST_FLOW=""

    installer_init_logging() { INSTALLER_LOG="test.log"; }
    installer_preflight() { :; }
    installer_choose_config() { REPLY="lua"; }

    installer_set_yes_no_option() {
        printf -v "$2" '%s' "no"
    }

    installer_strategy_plan() {
        TEST_FLOW+="T"
        return 1
    }

    installer_prepare_package_plan() {
        TEST_FLOW+="P"
        return 0
    }

    local status
    if installer_main >/dev/null 2>&1; then
        status=0
    else
        status=$?
    fi

    assert_eq 1 "$status" || return 1
    assert_eq "T" "$TEST_FLOW"
}

run_test test_main_stops_when_strategy_is_not_ready

run_test test_prompt_yes
run_test test_prompt_no
run_test test_prompt_default_yes
run_test test_prompt_default_no
run_test test_prompt_invalid_then_yes
run_test test_prompt_eof

run_test test_option_yes
run_test test_option_no
run_test test_option_eof

run_test test_choose_lua
run_test test_choose_conf
run_test test_choose_invalid_then_conf
run_test test_choose_eof

run_test test_backup_file
run_test test_backup_directory
run_test test_backup_symlinks
run_test test_backup_manifest
run_test test_backup_rejects_unsafe_paths
run_test test_backup_missing_path_is_ignored
run_test test_backup_duplicate_is_rejected

run_test test_restore_directory
run_test test_restore_symlinks
run_test test_restore_preserves_existing_destination
run_test test_restore_rejects_unsafe_paths
run_test test_restore_rejects_external_session
run_test test_restore_rejects_session_symlink

run_test test_package_collection_deduplicates_and_includes_options
run_test test_package_classification_separates_sources
run_test test_package_plan_rejects_unavailable_package
run_test test_package_plan_accepts_all_installed
run_test test_package_plan_rejects_other_repository
run_test test_package_plan_rejects_empty_request
run_test test_package_plan_marks_lookup_failures_unverified
run_test test_package_plan_marks_repository_list_failure_unverified
run_test test_main_stops_when_deployment_plan_is_not_ready
run_test test_main_runs_package_plan_before_summary_and_confirmation
run_test test_main_stops_when_package_plan_is_not_ready

printf '\n============================================\n'
printf 'Passed: %s\n' "$TESTS_PASSED"
printf 'Failed: %s\n' "$TESTS_FAILED"
printf '============================================\n'

if (( TESTS_FAILED > 0 )); then
    exit 1
fi

exit 0
