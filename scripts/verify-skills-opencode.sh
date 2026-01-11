#!/bin/bash

##############################################################################
# verify-skills-opencode.sh
#
# Purpose:
#   Integration test that verifies skills are discoverable by opencode.
#   Runs opencode with a prompt asking for available skills and checks
#   that all expected skills appear in the output.
#
# Usage:
#   ./scripts/verify-skills-opencode.sh
#
# Prerequisites:
#   - opencode CLI installed
#   - OpenCode Zen authenticated (for free model access)
#   - sync-skills.sh has been run (skills symlinked to .claude/skills/)
#
# Output:
#   TAP (Test Anything Protocol) format for CI integration
#
# Exit codes:
#   0 - All skills found in opencode output
#   1 - One or more skills missing from output
#   2 - Prerequisites not met (opencode not installed, not authenticated, etc.)
#
##############################################################################

set -e

# Get the repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

SKILLS_DIR="$REPO_ROOT/skills"

##############################################################################
# Discover all skills in the skills directory
##############################################################################
discover_skills() {
    find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

# Get expected skills (auto-discover)
declare -a EXPECTED_SKILLS
while IFS= read -r skill; do
    EXPECTED_SKILLS+=("$skill")
done < <(discover_skills)

# Configuration
OPENCODE_MODEL="opencode/gpt-5-nano"
OPENCODE_TIMEOUT=60
TEMP_OUTPUT=$(mktemp)
trap "rm -f $TEMP_OUTPUT" EXIT

# Counters
PASS=0
FAIL=0
TEST_NUM=0

##############################################################################
# Helper Functions
##############################################################################

tap_ok() {
    ((TEST_NUM++))
    ((PASS++))
    echo "ok $TEST_NUM - $1"
}

tap_not_ok() {
    ((TEST_NUM++))
    ((FAIL++))
    echo "not ok $TEST_NUM - $1"
    if [[ -n "$2" ]]; then
        echo "# $2"
    fi
}

check_prerequisites() {
    # Check if opencode is installed
    if ! command -v opencode &> /dev/null; then
        echo "not ok - opencode CLI not found"
        echo "# Install opencode: https://opencode.ai/docs/"
        return 1
    fi

    # Check if .claude/skills exists (should be created by sync-skills.sh)
    if [[ ! -d "$REPO_ROOT/.claude/skills" ]]; then
        echo "not ok - .claude/skills directory not found"
        echo "# Run: ./scripts/sync-skills.sh"
        return 1
    fi

    # Check if at least one skill symlink exists
    if ! ls "$REPO_ROOT/.claude/skills"/* &> /dev/null; then
        echo "not ok - No skills found in .claude/skills"
        echo "# Run: ./scripts/sync-skills.sh"
        return 1
    fi

    return 0
}

##############################################################################
# Main Logic
##############################################################################

# Check prerequisites first
if ! check_prerequisites; then
    exit 2
fi

TOTAL_TESTS=${#EXPECTED_SKILLS[@]}

echo "TAP version 14"
echo "1..$TOTAL_TESTS"
echo ""

# Run opencode with timeout
# Note: We use --format json to get structured output, but fall back to text parsing
PROMPT="What skills are available?"

if ! timeout "$OPENCODE_TIMEOUT" opencode run --model "$OPENCODE_MODEL" "$PROMPT" > "$TEMP_OUTPUT" 2>&1; then
    EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 124 ]]; then
        echo "not ok - opencode command timed out after ${OPENCODE_TIMEOUT}s"
        exit 2
    else
        echo "not ok - opencode command failed with exit code $EXIT_CODE"
        cat "$TEMP_OUTPUT" | sed 's/^/# /'
        exit 2
    fi
fi

# Search for each skill in the output
for skill_name in "${EXPECTED_SKILLS[@]}"; do
    if grep -qi "$skill_name" "$TEMP_OUTPUT"; then
        tap_ok "$skill_name found in opencode output"
    else
        tap_not_ok "$skill_name found in opencode output" "Skill not found in response"
    fi
done

echo ""
echo "# Tests: $PASS passed, $FAIL failed out of $TOTAL_TESTS"

if [[ $FAIL -gt 0 ]]; then
    echo "# Full opencode output:"
    cat "$TEMP_OUTPUT" | sed 's/^/# /'
    exit 1
fi

exit 0
