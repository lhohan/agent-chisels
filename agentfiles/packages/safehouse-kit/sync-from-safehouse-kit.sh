#!/usr/bin/env bash
set -euo pipefail

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

usage() {
    cat <<'EOF'
Usage: sync-from-safehouse-kit.sh [--source <path>] [--dry-run]

Synchronize safehouse-kit command assets from an external source directory
into this repository's packages/safehouse-kit layout.

Options:
  --source <path>  Source bin directory (default: ~/dev/safehouse-kit/bin)
  --dry-run        Print actions without copying files
  --help           Show this help message
EOF
}

script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P
}

write_public_wrapper() {
    local destination="$1"
    local command_name="$2"

    cat > "$destination" <<EOF
#!/usr/bin/env bash
set -euo pipefail

script_dir() {
    cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd -P
}

exec "\$(script_dir)/../lib/safehouse-kit/${command_name}" "\$@"
EOF

    chmod 0755 "$destination"
}

main() {
    local source_bin="$HOME/dev/safehouse-kit/bin"
    local dry_run="0"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --source)
                source_bin="$2"
                shift 2
                ;;
            --dry-run)
                dry_run="1"
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown argument: $1" >&2
                usage >&2
                exit 2
                ;;
        esac
    done

    local package_root
    package_root="$(script_dir)"

    local dst_bin="$package_root/.local/bin"
    local dst_lib="$package_root/.local/lib/safehouse-kit"
    local dst_vendor="$dst_lib/vendor"

    local -a public_cmds=(
        "safe"
        "safe-opencode"
        "soc"
        "safe-codex"
        "scx"
    )

    local -a internal_assets=(
        "safe"
        "safe-opencode"
        "soc"
        "safe-codex"
        "scx"
        "sandbox-agent.sh"
        "sandbox-agent.fish"
        "agents-local.sb"
    )

    local -a executable_assets=(
        "safe"
        "safe-opencode"
        "soc"
        "safe-codex"
        "scx"
        "sandbox-agent.sh"
    )

    local required
    for required in "${public_cmds[@]}" "${internal_assets[@]}" "vendor/safehouse"; do
        if [[ ! -e "$source_bin/$required" ]]; then
            echo "Missing required source asset: $source_bin/$required" >&2
            exit 1
        fi
    done

    if [[ "$dry_run" == "1" ]]; then
        log_message "Dry run mode enabled"
    fi

    if [[ "$dry_run" == "0" ]]; then
        mkdir -p "$dst_bin" "$dst_lib" "$dst_vendor"
    fi

    local cmd
    for cmd in "${public_cmds[@]}"; do
        log_message "Install public wrapper: $cmd"
        if [[ "$dry_run" == "0" ]]; then
            write_public_wrapper "$dst_bin/$cmd" "$cmd"
        fi
    done

    local asset
    for asset in "${internal_assets[@]}"; do
        log_message "Install internal asset: $asset"
        if [[ "$dry_run" == "0" ]]; then
            install -m 0644 "$source_bin/$asset" "$dst_lib/$asset"
        fi
    done

    log_message "Install vendored safehouse binary"
    if [[ "$dry_run" == "0" ]]; then
        install -m 0755 "$source_bin/vendor/safehouse" "$dst_vendor/safehouse"
    fi

    for asset in "${executable_assets[@]}"; do
        log_message "Mark executable: $dst_lib/$asset"
        if [[ "$dry_run" == "0" ]]; then
            chmod +x "$dst_lib/$asset"
        fi
    done

    if [[ "$dry_run" == "1" ]]; then
        log_message "Dry run completed: no files were modified"
    else
        log_message "Sync completed successfully"
    fi
}

main "$@"
