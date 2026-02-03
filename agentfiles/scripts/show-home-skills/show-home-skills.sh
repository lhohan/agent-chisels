#!/usr/bin/env bash

set -euo pipefail

if [[ -t 1 ]]; then
  COLOR_RESET=$'\033[0m'
  COLOR_HEADER=$'\033[1;35m'
  COLOR_WARN=$'\033[1;33m'
else
  COLOR_RESET=""
  COLOR_HEADER=""
  COLOR_WARN=""
fi

SKILL_DIRS=(
  "$HOME/.codex/skills"
  # "$HOME/.claude/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.vibe/skills"
)

show_skills_dir() {
  local dir="$1"

  printf '\n%b== %s ==%b\n' "$COLOR_HEADER" "$dir" "$COLOR_RESET"

  if [[ ! -d "$dir" ]]; then
    printf '%b(missing)%b\n' "$COLOR_WARN" "$COLOR_RESET"
    return 0
  fi

  ls -laG  --color=always "$dir/"
}

for dir in "${SKILL_DIRS[@]}"; do
  show_skills_dir "$dir"
done
