#!/usr/bin/env bash

# Script to compare skills across different coding agents
# Usage: ./compare-skills.sh [agent1] [agent2] ...

set -euo pipefail

# Default agents to compare if none specified
DEFAULT_AGENTS=("codex" "mistral-vibe" "opencode")

# Path to the prompt file
PROMPT_FILE="$(dirname "$0")/list-available-skills.md"

tmp_dir="$(mktemp -d)"
keep_temp=false

COLOR_RESET=""
COLOR_GREEN=""
ERROR_RESET=""
ERROR_BOLD=""
ERROR_RED=""
ERROR_YELLOW=""

setup_colors() {
    if [[ -t 1 && -n "${TERM:-}" && "$TERM" != "dumb" ]]; then
        COLOR_RESET=$'\033[0m'
        COLOR_GREEN=$'\033[32m'
    fi

    if [[ -t 2 && -n "${TERM:-}" && "$TERM" != "dumb" ]]; then
        ERROR_RESET=$'\033[0m'
        ERROR_BOLD=$'\033[1m'
        ERROR_RED=$'\033[31m'
        ERROR_YELLOW=$'\033[33m'
    fi
}

setup_colors

log_info() {
    printf '%s\n' "$*" >&2
}

log_success() {
    printf '%b\n' "${COLOR_GREEN}$*${COLOR_RESET}" >&2
}

log_warn() {
    printf '%b\n' "${ERROR_YELLOW}Warning: $*${ERROR_RESET}" >&2
}

log_error() {
    printf '%b\n' "${ERROR_RED}Error: $*${ERROR_RESET}" >&2
}

cleanup() {
    if [[ "$keep_temp" == "true" ]]; then
        log_warn "Keeping temp files in $tmp_dir"
    else
        rm -rf "$tmp_dir"
    fi
}

trap cleanup EXIT

json_escape() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//"/\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    value=${value//$'\t'/\\t}
    printf '%s' "$value"
}

print_json_array_inline() {
    local close_indent="$1"
    local item_indent="$2"
    shift 2
    local items=("$@")

    if [[ ${#items[@]} -eq 0 ]]; then
        printf '[]'
        return 0
    fi

    printf '[\n'
    local last_index=$(( ${#items[@]} - 1 ))
    for i in "${!items[@]}"; do
        local comma=","
        if [[ $i -eq $last_index ]]; then
            comma=""
        fi
        printf '%s"%s"%s\n' "$item_indent" "$(json_escape "${items[$i]}")" "$comma"
    done
    printf '%s]' "$close_indent"
}

parse_skills() {
    local input_file="$1"
    local output_file="$2"

    if grep -Fxq "No agent skills found." "$input_file"; then
        : > "$output_file"
        return 0
    fi

    awk '/^[[:space:]]*\*[[:space:]]+/ {
        sub(/^[[:space:]]*\*[[:space:]]+/, "", $0)
        gsub(/[[:space:]]+$/, "", $0)
        if (length($0) > 0) print $0
    }' "$input_file" | sort -u > "$output_file"
}

show_file() {
    local label="$1"
    local file_path="$2"

    if [[ -s "$file_path" ]]; then
        printf '%b\n' "${ERROR_BOLD}---- ${label} ----${ERROR_RESET}" >&2
        cat "$file_path" >&2
        printf '%b\n' "${ERROR_BOLD}---- end ${label} ----${ERROR_RESET}" >&2
    fi
}

agent_command() {
    local agent_name="$1"
    case "$agent_name" in
        codex)
            echo "codex --model \"gpt-5.1-codex-mini\" exec < \"$PROMPT_FILE\""
            ;;
        opencode)
            echo "opencode --model \"mistral/labs-devstral-small-2512\" run < \"$PROMPT_FILE\""
            ;;
        mistral-vibe|vibe)
            echo "vibe --agent explore --prompt < \"$PROMPT_FILE\""
            ;;
        *)
            echo ""
            ;;
    esac
}

run_agent() {
    local agent_name="$1"

    case "$agent_name" in
        codex)
            codex --model "gpt-5.1-codex-mini" exec < "$PROMPT_FILE"
            ;;
        opencode)
            opencode --model "mistral/labs-devstral-small-2512" run < "$PROMPT_FILE"
            ;;
        mistral-vibe|vibe)
            vibe --agent explore --prompt < "$PROMPT_FILE"
            ;;
        *)
            log_error "Unknown agent '$agent_name'"
            return 2
            ;;
    esac
}

validate_agent() {
    local agent_name="$1"
    case "$agent_name" in
        codex|opencode|mistral-vibe|vibe)
            return 0
            ;;
        *)
            log_error "Unknown agent '$agent_name'"
            return 2
            ;;
    esac
}

declare -a error_agents
declare -a error_codes
declare -a error_messages
declare -a error_commands
error_agents=()
error_codes=()
error_messages=()
error_commands=()

add_error() {
    local agent="$1"
    local code="$2"
    local message="$3"
    local command="${4:-}"

    error_agents+=("$agent")
    error_codes+=("$code")
    error_messages+=("$message")
    error_commands+=("$command")
}

call_agent() {
    local agent_name="$1"
    local stdout_file="$tmp_dir/${agent_name}.stdout"
    local stderr_file="$tmp_dir/${agent_name}.stderr"
    local skills_file="$tmp_dir/${agent_name}.skills"

    if ! run_agent "$agent_name" > "$stdout_file" 2> "$stderr_file"; then
        keep_temp=true
        log_error "$agent_name command failed."
        local command_line
        command_line="$(agent_command "$agent_name")"
        add_error "$agent_name" "agent_failed" "Agent command failed." "$command_line"
        if [[ -n "$command_line" ]]; then
            echo "Command: $command_line" >&2
        fi
        show_file "$agent_name stderr" "$stderr_file"
        return 1
    fi

    parse_skills "$stdout_file" "$skills_file"

    if [[ ! -s "$skills_file" ]] && ! grep -Fxq "No agent skills found." "$stdout_file"; then
        keep_temp=true
        log_error "No skills parsed for $agent_name."
        add_error "$agent_name" "no_skills_parsed" "No skills parsed from agent output." ""
        show_file "$agent_name stdout" "$stdout_file"
        return 1
    fi

    echo "$skills_file"
}

intersect_files() {
    local out_file="$1"
    shift
    local first_file="$1"
    shift

    cp "$first_file" "$out_file"
    while [[ $# -gt 0 ]]; do
        local next_file="$1"
        shift
        comm -12 "$out_file" "$next_file" > "$out_file.tmp"
        mv "$out_file.tmp" "$out_file"
    done
}

# Main execution
if [[ ! -f "$PROMPT_FILE" ]]; then
    log_error "Prompt file not found at $PROMPT_FILE"
    add_error "" "prompt_missing" "Prompt file not found." ""
    status="error"
    exit_code=2
    agents=("${DEFAULT_AGENTS[@]}")
    successful_agents=()
    failed_agents=()
    skill_files=()
    comparison_performed=false
    all_match=null
    common_skills=()
    only_in_files=()
else
    if [[ $# -eq 0 ]]; then
        agents=("${DEFAULT_AGENTS[@]}")
    else
        agents=("$@")
    fi

    declare -A skill_files
    declare -A only_in_files
    successful_agents=()
    failed_agents=()

    for agent in "${agents[@]}"; do
        log_info "=== Comparing skills for agent: $agent ==="
        if ! validate_agent "$agent"; then
            add_error "$agent" "unknown_agent" "Unknown agent '$agent'." ""
            failed_agents+=("$agent")
            continue
        fi
        if skill_path="$(call_agent "$agent")"; then
            skill_files["$agent"]="$skill_path"
            successful_agents+=("$agent")
        else
            failed_agents+=("$agent")
        fi
    done

    comparison_performed=false
    all_match=null
    common_skills=()

    if [[ ${#successful_agents[@]} -eq 0 ]]; then
        log_error "No agents succeeded; no comparison performed."
        add_error "" "no_agents_succeeded" "No agents succeeded; no comparison performed." ""
        status="error"
        exit_code=2
    elif [[ ${#successful_agents[@]} -lt 2 ]]; then
        log_warn "Only one agent succeeded; no comparison performed."
        add_error "" "insufficient_agents" "Only one agent succeeded; no comparison performed." ""
        status="error"
        exit_code=2
    else
        comparison_performed=true
        base_agent="${successful_agents[0]}"
        base_file="${skill_files["$base_agent"]}"
        all_match=true

        for agent in "${successful_agents[@]:1}"; do
            if ! cmp -s "$base_file" "${skill_files["$agent"]}"; then
                all_match=false
                break
            fi
        done

        common_file="$tmp_dir/common.skills"
        files_to_intersect=()
        for agent in "${successful_agents[@]}"; do
            files_to_intersect+=("${skill_files["$agent"]}")
        done
        intersect_files "$common_file" "${files_to_intersect[@]}"
        mapfile -t common_skills < "$common_file"

        for agent in "${successful_agents[@]}"; do
            others_union="$tmp_dir/${agent}.others.union"
            : > "$others_union"
            for other in "${successful_agents[@]}"; do
                if [[ "$other" != "$agent" ]]; then
                    cat "${skill_files["$other"]}" >> "$others_union"
                fi
            done
            sort -u "$others_union" -o "$others_union"

            only_file="$tmp_dir/${agent}.only"
            comm -23 "${skill_files["$agent"]}" "$others_union" > "$only_file"
            only_in_files["$agent"]="$only_file"
        done

        if [[ ${#failed_agents[@]} -gt 0 ]]; then
            status="partial"
            exit_code=3
        elif [[ "$all_match" == "true" ]]; then
            status="ok"
            exit_code=0
        else
            status="diff"
            exit_code=1
        fi
    fi
fi

# Emit JSON to stdout
printf '{\n'
printf '  "format_version": 1,\n'
printf '  "status": "%s",\n' "$(json_escape "$status")"
printf '  "exit_code": %s,\n' "$exit_code"
printf '  "prompt_file": "%s",\n' "$(json_escape "$PROMPT_FILE")"

printf '  "agents": {\n'
printf '    "requested": '
print_json_array_inline "    " "      " "${agents[@]}"
printf ',\n'
printf '    "successful": '
print_json_array_inline "    " "      " "${successful_agents[@]}"
printf ',\n'
printf '    "failed": '
print_json_array_inline "    " "      " "${failed_agents[@]}"
printf '\n'
printf '  },\n'

printf '  "skills": {\n'
printf '    "per_agent": {\n'
if [[ ${#successful_agents[@]} -gt 0 ]]; then
    last_index=$(( ${#successful_agents[@]} - 1 ))
    for i in "${!successful_agents[@]}"; do
        agent="${successful_agents[$i]}"
        printf '      "%s": ' "$(json_escape "$agent")"
        mapfile -t agent_skills < "${skill_files["$agent"]}"
        print_json_array_inline "      " "        " "${agent_skills[@]}"
        if [[ $i -lt $last_index ]]; then
            printf ',\n'
        else
            printf '\n'
        fi
    done
fi
printf '    },\n'
printf '    "common": '
print_json_array_inline "    " "      " "${common_skills[@]}"
printf '\n'
printf '  },\n'

printf '  "comparison": {\n'
printf '    "performed": %s,\n' "$comparison_performed"
if [[ "$comparison_performed" == "true" ]]; then
    printf '    "all_match": %s,\n' "$all_match"
    printf '    "only_in": {\n'
    if [[ ${#successful_agents[@]} -gt 0 ]]; then
        last_index=$(( ${#successful_agents[@]} - 1 ))
        for i in "${!successful_agents[@]}"; do
            agent="${successful_agents[$i]}"
            printf '      "%s": ' "$(json_escape "$agent")"
            mapfile -t only_skills < "${only_in_files["$agent"]}"
            print_json_array_inline "      " "        " "${only_skills[@]}"
            if [[ $i -lt $last_index ]]; then
                printf ',\n'
            else
                printf '\n'
            fi
        done
    fi
    printf '    }\n'
else
    printf '    "all_match": null,\n'
    printf '    "only_in": {}\n'
fi
printf '  },\n'

printf '  "errors": '
if [[ ${#error_agents[@]} -eq 0 ]]; then
    printf '[]'
else
    printf '[\n'
    last_index=$(( ${#error_agents[@]} - 1 ))
    for i in "${!error_agents[@]}"; do
        agent="${error_agents[$i]}"
        code="${error_codes[$i]}"
        message="${error_messages[$i]}"
        command="${error_commands[$i]}"
        printf '    {\n'
        if [[ -n "$agent" ]]; then
            printf '      "agent": "%s",\n' "$(json_escape "$agent")"
        else
            printf '      "agent": null,\n'
        fi
        printf '      "code": "%s",\n' "$(json_escape "$code")"
        printf '      "message": "%s",\n' "$(json_escape "$message")"
        if [[ -n "$command" ]]; then
            printf '      "command": "%s"\n' "$(json_escape "$command")"
        else
            printf '      "command": null\n'
        fi
        if [[ $i -lt $last_index ]]; then
            printf '    },\n'
        else
            printf '    }\n'
        fi
    done
    printf '  ]'
fi

printf ',\n'
printf '  "counts": {\n'
printf '    "per_agent": {\n'
if [[ ${#successful_agents[@]} -gt 0 ]]; then
    last_index=$(( ${#successful_agents[@]} - 1 ))
    for i in "${!successful_agents[@]}"; do
        agent="${successful_agents[$i]}"
        mapfile -t agent_skills < "${skill_files["$agent"]}"
        printf '      "%s": %s' "$(json_escape "$agent")" "${#agent_skills[@]}"
        if [[ $i -lt $last_index ]]; then
            printf ',\n'
        else
            printf '\n'
        fi
    done
fi
printf '    },\n'
printf '    "common": %s\n' "${#common_skills[@]}"
printf '  }\n'

printf '}\n'

exit "$exit_code"
