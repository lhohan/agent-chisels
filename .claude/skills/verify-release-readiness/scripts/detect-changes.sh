#!/bin/bash

##############################################################################
# detect-changes.sh
#
# Purpose:
#   Detects changed skills by comparing current revision to main.
#   Identifies affected skills and extracts version information.
#   Reports skills that need version updates based on changes since main.
#   Supports both Git and Jujutsu repositories.
#
# Usage:
#   ./detect-changes.sh
#
# Output:
#   JSON format with changed skills and version status
#
# Exit codes:
#   0 - Changes detected
#   1 - No changes found
#   2 - Error (not a git/jj repo, etc.)
#
##############################################################################

set -e

# Create temporary file and ensure cleanup
CHANGES_FILE=$(mktemp)
trap "rm -f $CHANGES_FILE" EXIT

# Get the repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Script is in .claude/skills/verify-release-readiness/scripts/
# Need to go up 4 levels to reach repo root
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

SKILLS_DIR="$REPO_ROOT/skills"

##############################################################################
# Helper Functions
##############################################################################

extract_frontmatter_field() {
    local file="$1"
    local field="$2"

    # Extract field value from YAML frontmatter (between --- markers)
    sed -n '/^---$/,/^---$/p' "$file" | grep "^$field:" | head -1 | sed "s/^$field: *//" | tr -d '"'
}

##############################################################################
# VCS Detection
##############################################################################

# Detect VCS type
if [ -d "$REPO_ROOT/.jj" ]; then
    VCS="jj"
    BASE_REF="main@origin"
elif [ -d "$REPO_ROOT/.git" ]; then
    VCS="git"
    BASE_REF="origin/main"
else
    echo "Error: Not a Git or Jujutsu repository" >&2
    exit 2
fi

##############################################################################
# Main Logic
##############################################################################

# Get the list of changed files (comparing current to main)
if [ "$VCS" = "jj" ]; then
    # Jujutsu: compare @ to main@origin
    if ! jj diff --from main@origin --to @ --summary --no-pager > "$CHANGES_FILE" 2>&1; then
        echo "Error: Failed to get changes from main bookmark" >&2
        exit 2
    fi
elif [ "$VCS" = "git" ]; then
    # Git: compare HEAD to origin/main, show summary
    # Use --name-status to get a similar format to jj diff --summary
    if ! git diff --name-status origin/main...HEAD > "$CHANGES_FILE" 2>&1; then
        echo "Error: Failed to get changes from origin/main" >&2
        exit 2
    fi
fi

# Extract skills that have changed
changed_skills=()
skill_changes=()

while IFS= read -r line; do
    # Parse diff output format: "M    path/to/file" (jj) or "M\tpath/to/file" (git)
    # We need to extract skill names from paths like: skills/skill-name/...
    # ⏺ This regex matches both git and jj diff output formats and extracts the skill name. Let me break it down:
    #   ^[[:space:]]*[A-Z][[:space:]]+skills/([^/]+)/
    #   Part: ^
    #   Meaning: Start of line - anchors to the beginning
    #   ────────────────────────────────────────
    #   Part: [[:space:]]*
    #   Meaning: Zero or more whitespace characters - handles any leading spaces
    #   ────────────────────────────────────────
    #   Part: [A-Z]
    #   Meaning: Single uppercase letter - matches the jj status code (M=modified, A=added,
    #     D=deleted, etc.)
    #   ────────────────────────────────────────
    #   Part: [[:space:]]+
    #   Meaning: One or more whitespace characters - the gap between status and path
    #   ────────────────────────────────────────
    #   Part: skills/
    #   Meaning: Literal string - matches only skills/ directory, NOT .claude/skills/
    #   ────────────────────────────────────────
    #   Part: ([^/]+)
    #   Meaning: Capturing group - matches the skill name (anything that's NOT a /)
    #   ────────────────────────────────────────
    #   Part: /
    #   Meaning: Literal forward slash - the slash after the skill name
    #   Example

    #   For these diff lines:
    #   Jujutsu: M    skills/detecting-jujutsu/SKILL.md
    #   Git:     M\tskills/detecting-jujutsu/SKILL.md

    #   The regex matches both:
    #   - M - the status
    #   -      (spaces or tab) - the whitespace
    #   - skills/ - the directory
    #   - detecting-jujutsu - captured as the skill name
    #   - / - the separator

    #   Why It Excludes .claude/skills/

    #   Lines like A .claude/skills/preparing-release/SKILL.md won't match because:
    #   - After the status letter A, the next thing is .claude/skills/...
    #   - The pattern requires skills/ to come immediately after the status+whitespace
    #   - The .claude/ prefix breaks the match, so it never reaches the skills/ part
    if [[ $line =~ ^[[:space:]]*[A-Z][[:space:]]+skills/([^/]+)/ ]]; then
        skill_name="${BASH_REMATCH[1]}"
        # Check if we haven't seen this skill yet
        if [[ ! " ${changed_skills[@]} " =~ " ${skill_name} " ]]; then
            changed_skills+=("$skill_name")
        fi
        skill_changes+=("$line")
     fi
done < "$CHANGES_FILE"

# If no changes detected
if [[ ${#changed_skills[@]} -eq 0 ]]; then
    echo "No skill changes detected" >&2
    exit 1
fi

# Start building JSON output
echo "{"
echo '  "changed_skills": ['

first=true
for skill_name in "${changed_skills[@]}"; do
    skill_file="$SKILLS_DIR/$skill_name/SKILL.md"
    # Use relative path for jj commands
    skill_file_rel="skills/$skill_name/SKILL.md"

    # Verify skill exists and has SKILL.md
    if [[ ! -f "$skill_file" ]]; then
        continue
    fi

    # Get current version
    current_version=$(extract_frontmatter_field "$skill_file" "version")

    # Get version from main using VCS-specific commands
    if [ "$VCS" = "jj" ]; then
        # Jujutsu: use jj file show
        main_version=$(jj file show -r main@origin "$skill_file_rel" 2>/dev/null | sed -n '/^---$/,/^---$/p' | grep "^version:" | head -1 | sed "s/^version: *//" | tr -d '"' || echo "")
    elif [ "$VCS" = "git" ]; then
        # Git: use git show
        main_version=$(git show origin/main:"$skill_file_rel" 2>/dev/null | sed -n '/^---$/,/^---$/p' | grep "^version:" | head -1 | sed "s/^version: *//" | tr -d '"' || echo "")
    fi

    # Determine if version needs update
    needs_update="false"
    if [[ "$current_version" == "$main_version" ]] && [[ -n "$current_version" ]]; then
        needs_update="true"
    fi

    # Get list of changed files for this skill
    changed_files="["
    file_count=0
    while IFS= read -r change_line; do
        if [[ $change_line =~ ^[[:space:]]*[A-Z][[:space:]]+skills/${skill_name}/ ]]; then
            # Extract just the file path
            file_path=$(echo "$change_line" | sed 's/^[A-Z]\s\+//' | xargs)
            if [[ -n "$file_path" ]]; then
                if [[ $file_count -gt 0 ]]; then
                    changed_files="$changed_files,"
                fi
                changed_files="$changed_files\"$file_path\""
                ((file_count++))
            fi
         fi
     done < "$CHANGES_FILE"
     changed_files="$changed_files]"

    # Add JSON entry
    if [[ "$first" == "true" ]]; then
        first=false
    else
        echo ","
    fi

    echo -n "    {"
    echo -n "\"name\": \"$skill_name\", "
    echo -n "\"current_version\": \"$current_version\", "
    echo -n "\"main_version\": \"$main_version\", "
    echo -n "\"needs_update\": $needs_update, "
    echo -n "\"changed_files\": $changed_files"
    echo -n "}"
done

echo ""
echo "  ]"
echo "}"

exit 0
