#!/bin/bash

##############################################################################
# verify-skills-static.sh
#
# Purpose:
#   Validates skill files in the repository without running opencode.
#   Checks for file existence, valid YAML frontmatter, and naming consistency.
#
# Usage:
#   ./scripts/verify-skills-static.sh
#
# Output:
#   TAP (Test Anything Protocol) format for CI integration
#
# Exit codes:
#   0 - All validations pass
#   1 - One or more validations fail
#
##############################################################################

set -e

# Get the repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

SKILLS_DIR="$REPO_ROOT/skills"

# Expected skills to validate
declare -a EXPECTED_SKILLS=(
    "detecting-jujutsu"
    "using-jujutsu"
    "evaluating-skills"
    "documenting-architectural-decisions"
)

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

extract_frontmatter_field() {
    local file="$1"
    local field="$2"
    
    # Extract field value from YAML frontmatter (between --- markers)
    sed -n '/^---$/,/^---$/p' "$file" | grep "^$field:" | head -1 | sed "s/^$field: *//" | tr -d '"'
}

##############################################################################
# Main Logic
##############################################################################

echo "TAP version 14"
echo "1..$((${#EXPECTED_SKILLS[@]} * 5))"
echo ""

TOTAL_TESTS=$((${#EXPECTED_SKILLS[@]} * 5))

for skill_name in "${EXPECTED_SKILLS[@]}"; do
    skill_path="$SKILLS_DIR/$skill_name"
    skill_file="$skill_path/SKILL.md"
    
    # Test 1: File exists
    if [[ -f "$skill_file" ]]; then
        tap_ok "$skill_name/SKILL.md exists"
    else
        tap_not_ok "$skill_name/SKILL.md exists" "File not found: $skill_file"
        continue
    fi
    
    # Test 2: Has 'name' field in frontmatter
    name_value=$(extract_frontmatter_field "$skill_file" "name")
    if [[ -n "$name_value" ]]; then
        tap_ok "$skill_name has 'name' field in frontmatter"
    else
        tap_not_ok "$skill_name has 'name' field in frontmatter" "Missing or empty 'name' field"
        continue
    fi
    
    # Test 3: Has 'description' field in frontmatter
    description_value=$(extract_frontmatter_field "$skill_file" "description")
    if [[ -n "$description_value" ]]; then
        tap_ok "$skill_name has 'description' field in frontmatter"
    else
        tap_not_ok "$skill_name has 'description' field in frontmatter" "Missing or empty 'description' field"
        continue
    fi
    
    # Test 4: 'name' field matches directory name
    if [[ "$name_value" == "$skill_name" ]]; then
        tap_ok "$skill_name 'name' field matches directory name"
    else
        tap_not_ok "$skill_name 'name' field matches directory name" "Expected '$skill_name', got '$name_value'"
    fi
    
    # Test 5: Has 'version' field in frontmatter
    version_value=$(extract_frontmatter_field "$skill_file" "version")
    if [[ -n "$version_value" ]]; then
        tap_ok "$skill_name has 'version' field in frontmatter"
    else
        tap_not_ok "$skill_name has 'version' field in frontmatter" "Missing or empty 'version' field"
    fi
done

echo ""
echo "# Tests: $PASS passed, $FAIL failed out of $TOTAL_TESTS"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi

exit 0
