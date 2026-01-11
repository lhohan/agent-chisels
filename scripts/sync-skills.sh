#!/bin/bash

##############################################################################
# sync-skills.sh
#
# Purpose:
#   Synchronizes skills from the repo's skills/ directory to .claude/skills/
#   by creating symlinks. This allows AI agents to discover and use skills
#   defined in this repository.
#
# Usage:
#   ./scripts/sync-skills.sh
#
# Behavior:
#   1. Creates .claude/skills/ directory if it doesn't exist
#   2. For each skill in skills/:
#      - Creates symlink: .claude/skills/[skill-name] -> ../../skills/[skill-name]
#      - Skips and warns if a non-symlink or mismatched symlink exists
#   3. Cleanup: Removes symlinks in .claude/skills/ that point to skills
#      no longer present in skills/
#
# Exit codes:
#   0 - Success
#   1 - Error (e.g., unable to create directory)
#
##############################################################################

set -e

# Get the repo root (directory containing this script's parent)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

SKILLS_DIR="$REPO_ROOT/skills"
CLAUDE_SKILLS_DIR="$REPO_ROOT/.claude/skills"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
CREATED=0
SKIPPED=0
CLEANED=0
WARNINGS=0

##############################################################################
# Helper Functions
##############################################################################

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

##############################################################################
# Main Logic
##############################################################################

echo "Syncing skills from $SKILLS_DIR to $CLAUDE_SKILLS_DIR"
echo ""

# Create .claude/skills directory if it doesn't exist
if [[ ! -d "$CLAUDE_SKILLS_DIR" ]]; then
    mkdir -p "$CLAUDE_SKILLS_DIR"
    log_success "Created $CLAUDE_SKILLS_DIR"
fi

# Check if skills directory exists
if [[ ! -d "$SKILLS_DIR" ]]; then
    log_error "Skills directory not found: $SKILLS_DIR"
    exit 1
fi

# Phase 1: Create symlinks for skills
echo "Phase 1: Creating symlinks for skills..."
for skill_path in "$SKILLS_DIR"/*; do
    if [[ ! -d "$skill_path" ]]; then
        continue
    fi
    
    skill_name=$(basename "$skill_path")
    target_link="$CLAUDE_SKILLS_DIR/$skill_name"
    
    # Calculate relative path from .claude/skills to skills/[skill-name]
    relative_path="../../skills/$skill_name"
    
    if [[ ! -e "$target_link" ]]; then
        # Target doesn't exist, create symlink
        ln -s "$relative_path" "$target_link"
        log_success "Created symlink: $skill_name"
        ((CREATED++))
    elif [[ -L "$target_link" ]]; then
        # Target is a symlink, check if it points to the right place
        current_target=$(readlink "$target_link")
        if [[ "$current_target" == "$relative_path" ]]; then
            # Already correct, skip
            ((SKIPPED++))
        else
            # Points elsewhere, warn and skip
            log_warn "Symlink exists but points elsewhere: $skill_name (points to $current_target)"
            ((SKIPPED++))
        fi
    else
        # Target exists but is not a symlink
        log_warn "File/directory exists but is not a symlink: $skill_name"
        ((SKIPPED++))
    fi
done

echo ""
echo "Phase 2: Cleaning up orphaned symlinks..."

# Phase 2: Remove symlinks that point to skills no longer in skills/
for link_path in "$CLAUDE_SKILLS_DIR"/*; do
    if [[ ! -L "$link_path" ]]; then
        continue
    fi
    
    link_name=$(basename "$link_path")
    skill_source="$SKILLS_DIR/$link_name"
    
    # Check if the symlink points into this repo's skills directory
    link_target=$(readlink "$link_path")
    if [[ "$link_target" == *"/skills/"* ]]; then
        # It's a symlink we created, check if source still exists
        if [[ ! -d "$skill_source" ]]; then
            rm "$link_path"
            log_success "Removed orphaned symlink: $link_name"
            ((CLEANED++))
        fi
    fi
done

echo ""
echo "=========================================="
echo "Sync complete!"
echo "  Created:  $CREATED"
echo "  Skipped:  $SKIPPED"
echo "  Cleaned:  $CLEANED"
echo "  Warnings: $WARNINGS"
echo "=========================================="

if [[ $WARNINGS -gt 0 ]]; then
    exit 1
fi

exit 0
