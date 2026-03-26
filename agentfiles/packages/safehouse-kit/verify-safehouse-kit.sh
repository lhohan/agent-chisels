#!/usr/bin/env bash
set -euo pipefail

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

require_file() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "Missing required file: $path" >&2
        exit 1
    fi
}

require_executable() {
    local path="$1"
    require_file "$path"
    if [[ ! -x "$path" ]]; then
        echo "Expected executable file: $path" >&2
        exit 1
    fi
}

script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P
}

main() {
    local root
    root="$(script_dir)"

    local sync_script="$root/sync-from-safehouse-kit.sh"

    local -a public_wrappers=(
        "$root/.local/bin/safe"
        "$root/.local/bin/safe-opencode"
        "$root/.local/bin/soc"
        "$root/.local/bin/safe-codex"
        "$root/.local/bin/scx"
    )

    local -a internal_execs=(
        "$root/.local/lib/safehouse-kit/safe"
        "$root/.local/lib/safehouse-kit/safe-opencode"
        "$root/.local/lib/safehouse-kit/soc"
        "$root/.local/lib/safehouse-kit/safe-codex"
        "$root/.local/lib/safehouse-kit/scx"
        "$root/.local/lib/safehouse-kit/sandbox-agent.sh"
        "$root/.local/lib/safehouse-kit/vendor/safehouse"
    )

    local -a internal_files=(
        "$root/.local/lib/safehouse-kit/sandbox-agent.fish"
        "$root/.local/lib/safehouse-kit/agents-local.sb"
    )

    log_message "Check sync script syntax"
    bash -n "$sync_script"

    log_message "Run dry-run and verify no-op marker"
    local dry_run_output
    dry_run_output="$($sync_script --dry-run)"
    if [[ "$dry_run_output" != *"Dry run completed: no files were modified"* ]]; then
        echo "Dry-run output is missing no-op completion marker" >&2
        exit 1
    fi

    log_message "Check public wrapper executables"
    local path
    for path in "${public_wrappers[@]}"; do
        require_executable "$path"
    done

    log_message "Check public wrapper runtime pathing"
    "$root/.local/bin/safe" -- /usr/bin/true

    log_message "Check internal executable assets"
    for path in "${internal_execs[@]}"; do
        require_executable "$path"
    done

    log_message "Check internal non-executable assets"
    for path in "${internal_files[@]}"; do
        require_file "$path"
    done

    log_message "Verification completed successfully"
}

main "$@"
