#!/usr/bin/env bash
set -euo pipefail

script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P
}

safehouse_bin() {
    printf '%s/vendor/safehouse\n' "$(script_dir)"
}

run_passthrough() {
    if [[ $# -eq 0 ]]; then
        printf 'no command specified\n' >&2
        exit 1
    fi

    local cmd_token="$1"
    local cmd_link_path="$cmd_token"
    local cmd_real_path cmd_dir cmd_real_dir

    local host_path="${PATH:-}"
    local sandbox_path
    sandbox_path="$(sanitize_path_for_sandbox "$host_path")"

    grant_paths=""
    append_path_dir_grants "$sandbox_path"

    if [[ "$cmd_token" != */* ]]; then
        # Resolve against the sanitized PATH so we prefer real, granted tool dirs
        # (e.g. /nix/store/.../bin) over profile symlink shims.
        cmd_link_path="$(PATH="$sandbox_path" type -P "$cmd_token" 2>/dev/null || true)"
        if [[ -z "$cmd_link_path" ]]; then
            # Fallback to host PATH resolution.
            cmd_link_path="$(type -P "$cmd_token" 2>/dev/null || true)"
        fi
        if [[ -z "$cmd_link_path" ]]; then
            printf 'sandbox-agent: command not found: %s\n' "$cmd_token" >&2
            exit 127
        fi
    fi

    cmd_real_path="$(realpath "$cmd_link_path" 2>/dev/null || true)"
    if [[ -z "$cmd_real_path" ]]; then
        printf 'sandbox-agent: failed to resolve realpath for %s\n' "$cmd_link_path" >&2
        exit 1
    fi

    cmd_dir="$(dirname "$cmd_link_path")"
    cmd_real_dir="$(dirname "$cmd_real_path")"
    append_grant_path "$cmd_dir"
    append_grant_path "$cmd_real_dir"
    append_nix_store_dylib_grants "$cmd_real_path"

    if [[ "${SANDBOX_AGENT_TRACE:-0}" == "1" ]]; then
        printf 'sandbox-agent exec:' >&2
        printf ' %q' "$(safehouse_bin)" --explain --add-dirs-ro="$grant_paths" --env-pass=PATH --env-pass=OPENCODE_PERMISSION -- "$cmd_link_path" "${@:2}" >&2
        printf '\n' >&2
    fi

    PATH="$sandbox_path" exec "$(safehouse_bin)" --explain --add-dirs-ro="$grant_paths" --env-pass=PATH --env-pass=OPENCODE_PERMISSION -- "$cmd_link_path" "${@:2}"
}

grant_paths=""

# Mutates global `grant_paths` used by run_agent/build_agent_safehouse_cmd.
append_grant_path() {
    local path="$1"

    [[ -n "$path" ]] || return 0

    if [[ -z "${grant_paths:-}" ]]; then
        grant_paths="$path"
    else
        grant_paths="${grant_paths}:$path"
    fi
}

append_nix_store_dylib_grants() {
    local binary_path="$1"

    command -v otool >/dev/null 2>&1 || return 0

    local -a queue=()
    local visited dep dep_real line trimmed current
    visited=$'\n'
    queue+=("$binary_path")

    while [[ ${#queue[@]} -gt 0 ]]; do
        current="${queue[0]}"
        queue=("${queue[@]:1}")

        while IFS= read -r line; do
            [[ -n "$line" ]] || continue
            [[ "$line" == *: ]] && continue

            trimmed="${line#"${line%%[![:space:]]*}"}"
            dep="${trimmed%% *}"

            [[ "$dep" == /nix/store/* ]] || continue
            [[ -e "$dep" ]] || continue

            case "$visited" in
                *$'\n'"$dep"$'\n'*)
                    continue
                    ;;
            esac
            visited+="$dep"$'\n'

            append_grant_path "$dep"
            queue+=("$dep")

            dep_real="$(realpath "$dep" 2>/dev/null || true)"
            if [[ -n "$dep_real" && "$dep_real" != "$dep" ]]; then
                append_grant_path "$dep_real"

                case "$visited" in
                    *$'\n'"$dep_real"$'\n'*)
                        ;;
                    *)
                        visited+="$dep_real"$'\n'
                        queue+=("$dep_real")
                        ;;
                esac
            fi
        done < <(otool -L "$current" 2>/dev/null || true)
    done
}

append_path_dir_grants() {
    local raw_path="$1"
    local path_entry path_real

    IFS=':' read -r -a _path_entries <<< "$raw_path"
    for path_entry in "${_path_entries[@]}"; do
        [[ -d "$path_entry" ]] || continue
        path_real="$(realpath "$path_entry" 2>/dev/null || true)"
        [[ -n "$path_real" ]] || path_real="$path_entry"
        append_grant_path "$path_real"
    done

    [[ -d /nix/store ]] && append_grant_path "/nix/store"
}

sanitize_path_for_sandbox() {
    local raw_path="$1"
    local -a out=()
    local seen entry real

    seen=$'\n'
    IFS=':' read -r -a _path_entries <<< "$raw_path"
    for entry in "${_path_entries[@]}"; do
        [[ -d "$entry" ]] || continue
        real="$(realpath "$entry" 2>/dev/null || true)"
        [[ -n "$real" ]] || real="$entry"

        case "$seen" in
            *$'\n'"$real"$'\n'*)
                continue
                ;;
        esac
        seen+="$real"$'\n'
        out+=("$real")
    done

    (IFS=':'; printf '%s' "${out[*]}")
}

# Builds global `cmd` array for optional trace + exec in run_agent.
build_agent_safehouse_cmd() {
    local agent_real_path="$1"
    local local_profile="$2"
    shift 2
    cmd=(
        "$(safehouse_bin)"
        --explain
        --add-dirs-ro="${grant_paths}"
        --append-profile="$local_profile"
        --env-pass=PATH
        --env-pass=OPENCODE_PERMISSION
        --
        "$agent_real_path"
        "$@"
    )
}

run_agent() {
    local agent_name="$1"
    shift
    local agent_link_path
    local agent_real_path
    local local_profile

    local host_path="${PATH:-}"
    local sandbox_path

    grant_paths=""

    agent_link_path="$(command -v "$agent_name" 2>/dev/null || true)"
    if [[ -z "$agent_link_path" ]]; then
        printf 'sandbox-agent: command not found: %s\n' "$agent_name" >&2
        exit 127
    fi
    append_grant_path "$agent_link_path"

    agent_real_path="$(realpath "$agent_link_path" 2>/dev/null || true)"
    if [[ -z "$agent_real_path" ]]; then
        printf 'sandbox-agent: failed to resolve realpath for %s\n' "$agent_link_path" >&2
        exit 1
    fi
    append_grant_path "$agent_real_path"

    append_nix_store_dylib_grants "$agent_real_path"
    sandbox_path="$(sanitize_path_for_sandbox "$host_path")"
    append_path_dir_grants "$sandbox_path"

    # Shared local grants profile for all agent launches.
    local_profile="$(script_dir)/agents-local.sb"
    if [[ ! -f "$local_profile" ]]; then
        printf 'sandbox-agent: required local profile not found: %s\n' "$local_profile" >&2
        exit 1
    fi

    build_agent_safehouse_cmd "$agent_real_path" "$local_profile" "$@"

    if [[ "${SANDBOX_AGENT_TRACE:-0}" == "1" ]]; then
        printf 'sandbox-agent exec:' >&2
        printf ' %q' "${cmd[@]}" >&2
        printf '\n' >&2
    fi

    PATH="$sandbox_path" exec "${cmd[@]}"
}

main() {
    case "${1:-}" in
        "")
            # Keep existing behavior: no args = success no-op
            exit 0
            ;;
        "--")
            shift
            run_passthrough "$@"
            ;;
        "opencode"|"codex")
            local agent="$1"
            shift
            run_agent "$agent" "$@"
            ;;
        *)
            printf 'Usage: sandbox-agent opencode [args...]\n' >&2
            printf '       sandbox-agent codex [args...]\n' >&2
            printf '       sandbox-agent -- <cmd...>\n' >&2
            exit 2
            ;;
    esac
}

main "$@"
