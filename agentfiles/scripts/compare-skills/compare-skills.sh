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

cleanup() {
    if [[ "$keep_temp" == "true" ]]; then
        echo "Keeping temp files in $tmp_dir" >&2
    else
        rm -rf "$tmp_dir"
    fi
}

trap cleanup EXIT

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
        echo "---- ${label} ----" >&2
        cat "$file_path" >&2
        echo "---- end ${label} ----" >&2
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
            echo "Error: Unknown agent '$agent_name'" >&2
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
            echo "Error: Unknown agent '$agent_name'" >&2
            return 2
            ;;
    esac
}

call_agent() {
    local agent_name="$1"
    local stdout_file="$tmp_dir/${agent_name}.stdout"
    local stderr_file="$tmp_dir/${agent_name}.stderr"
    local skills_file="$tmp_dir/${agent_name}.skills"

    if ! run_agent "$agent_name" > "$stdout_file" 2> "$stderr_file"; then
        keep_temp=true
        echo "Error: $agent_name command failed." >&2
        command_line="$(agent_command "$agent_name")"
        if [[ -n "$command_line" ]]; then
            echo "Command: $command_line" >&2
        fi
        show_file "$agent_name stderr" "$stderr_file"
        return 1
    fi

    parse_skills "$stdout_file" "$skills_file"

    if [[ ! -s "$skills_file" ]] && ! grep -Fxq "No agent skills found." "$stdout_file"; then
        keep_temp=true
        echo "Error: No skills parsed for $agent_name." >&2
        show_file "$agent_name stdout" "$stdout_file"
        return 1
    fi

    echo "$skills_file"
}

print_skills() {
    local file_path="$1"
    if [[ -s "$file_path" ]]; then
        while IFS= read -r skill; do
            echo "* $skill"
        done < "$file_path"
    else
        echo "No agent skills found."
    fi
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
    echo "Error: Prompt file not found at $PROMPT_FILE" >&2
    exit 2
fi

if [[ $# -eq 0 ]]; then
    agents=("${DEFAULT_AGENTS[@]}")
else
    agents=("$@")
fi

declare -A skill_files
successful_agents=()
failed_agents=()

for agent in "${agents[@]}"; do
    echo "=== Comparing skills for agent: $agent ==="
    if ! validate_agent "$agent"; then
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

if [[ ${#successful_agents[@]} -eq 0 ]]; then
    echo "No agents succeeded; no comparison performed." >&2
    exit 2
fi

if [[ ${#successful_agents[@]} -lt 2 ]]; then
    echo "Only one agent succeeded; no comparison performed."
    print_skills "${skill_files["${successful_agents[0]}"]}"
    if [[ ${#failed_agents[@]} -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

base_agent="${successful_agents[0]}"
base_file="${skill_files["$base_agent"]}"
all_match=true

for agent in "${successful_agents[@]:1}"; do
    if ! cmp -s "$base_file" "${skill_files["$agent"]}"; then
        all_match=false
        break
    fi
done

if [[ "$all_match" == "true" ]]; then
    echo "All skills match across: ${successful_agents[*]}"
    print_skills "$base_file"
    if [[ ${#failed_agents[@]} -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

common_file="$tmp_dir/common.skills"
files_to_intersect=()
for agent in "${successful_agents[@]}"; do
    files_to_intersect+=("${skill_files["$agent"]}")
done
intersect_files "$common_file" "${files_to_intersect[@]}"

echo "Common skills:"
print_skills "$common_file"

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

    echo "Only in $agent:"
    print_skills "$only_file"
done

if [[ ${#failed_agents[@]} -gt 0 ]]; then
    echo "Some agents failed: ${failed_agents[*]}" >&2
    exit 1
fi

exit 1
