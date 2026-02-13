#!/bin/bash

# Sync shared skills into project-level .claude/skills/.
#
# Why:
# - Enables dogfooding skills inside this repository.
# - Provides a stable, conventional discovery path for multiple agents.
#
# Usage:
#   ./scripts/sync-skills.sh
#   ./scripts/sync-skills.sh --dry-run

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

SOURCE_DIR="$REPO_ROOT/agentfiles/shared/skills"
TARGET_DIR="$REPO_ROOT/.claude/skills"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: skills source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

link_skill_dir() {
  local skill_name="$1"
  local dest="$TARGET_DIR/$skill_name"
  local rel_src="../../agentfiles/shared/skills/$skill_name"

  if [[ -L "$dest" ]]; then
    # If it's already the expected link, keep it.
    local current
    current="$(readlink "$dest")"
    if [[ "$current" == "$rel_src" ]]; then
      return 0
    fi
  elif [[ -e "$dest" ]]; then
    echo "WARN: $dest exists and is not a symlink; skipping" >&2
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "PLAN link $dest -> $rel_src"
    return 0
  fi

  ln -sfn "$rel_src" "$dest"
  echo "OK   link $dest -> $rel_src"
}

for dir in "$SOURCE_DIR"/*; do
  [[ -d "$dir" ]] || continue
  skill_name="$(basename "$dir")"
  link_skill_dir "$skill_name"
done

if [[ "$DRY_RUN" == "true" ]]; then
  echo "SUMMARY dry_run=true"
else
  echo "SUMMARY dry_run=false"
fi
