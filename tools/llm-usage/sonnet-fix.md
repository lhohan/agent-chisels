# LLM Usage Tool - Bug Fixes Summary

## Overview

Fixed critical bugs preventing the `llm-usage` tool from working and tests from compiling/passing.

## Issue 1: Tests Not Compiling ✅ FIXED

### Problems
1. Module `dsl` was private in `lib.rs`, causing import errors
2. Missing/incorrect imports in test files (using `json!` macro incorrectly)

### Fixes
1. Made `dsl` module public in `cli-tests/src/lib.rs`
2. Fixed imports in `tests/all_mode.rs` to use `Value::String()` instead of `json!("")`

## Issue 2: Tool Not Working ✅ FIXED

### Problem 1: OpenCode Messages Showing 0
**Symptom:** Tool found 598 sessions but reported 0 messages

**Root Cause:** The `ls` command was hitting shell glob limits (ARG_MAX) when trying to expand `~/.local/share/opencode/storage/message/ses_*/msg_*.json` with 10,800+ files.

**Fix:** Replaced `ls -A "$messages_dir"/ses_*/msg_*.json` with `find "$messages_dir" -path "*/ses_*/msg_*.json" -print -quit` in `load_opencode_all()` function (line 232).

### Problem 2: Project Discovery Failing
**Symptom:** Tests failing with "No LLM usage data found for current directory" even though data existed

**Root Cause:** macOS symlink issue - `/var` is a symlink to `/private/var`. The script was comparing:
- Worktree path: `/var/folders/.../workspace/repo/my-proj` (stored in project file)
- Current directory: `/private/var/folders/.../workspace/repo/my-proj` (from `pwd`)

These didn't match due to symlink resolution.

**Fix:** Added path canonicalization in `load_opencode_stats()`:
```bash
local canonical_project_path
canonical_project_path=$(cd "$project_path" 2>/dev/null && pwd -P || echo "$project_path")

local canonical_wt
canonical_wt=$(cd "$wt" 2>/dev/null && pwd -P || echo "$wt")
```

### Problem 3: Claude Code Not Found During Walking
**Symptom:** Test `default_mode_discovers_project` failing - OpenCode found but Claude Code not found when walking up directories

**Root Cause:** The `url_encode` function creates directory names like `-var-folders-...-my-proj`, but when the script canonicalizes paths, it gets `/private/var/folders/...` which encodes differently.

**Fix:** Added fallback logic in `load_claude_stats()` to search all Claude project directories by checking the `cwd` field in JSONL files:
```bash
# If still not found, try to find any matching directory by checking all directories
if [[ ! -d "$project_dir" ]] && [[ -d "$CLAUDE_PROJECTS" ]]; then
    local non_canonical_path="${canonical_project_path#/private}"
    
    for dir in "$CLAUDE_PROJECTS"/*; do
        if [[ -d "$dir" ]]; then
            for jsonl in "$dir"/*.jsonl; do
                if [[ -f "$jsonl" ]]; then
                    if grep -q "\"cwd\":\"$canonical_project_path\"" "$jsonl" 2>/dev/null || \
                       grep -q "\"cwd\":\"$project_path\"" "$jsonl" 2>/dev/null || \
                       grep -q "\"cwd\":\"$non_canonical_path\"" "$jsonl" 2>/dev/null; then
                        project_dir="$dir"
                        break 2
                    fi
                fi
            done
        fi
    done
fi
```

### Problem 4: Token Aggregation Wrong
**Symptom:** Test `tokens_sum_across_sessions` expecting 1000 tokens but getting 600

**Root Cause:** The `load_claude_stats()` function was processing each session file individually and overwriting aggregated data instead of accumulating it.

**Fix:** Refactored to collect all entries from all sessions first, then aggregate:
```bash
local all_entries_combined='[]'

# Collect all entries from all sessions
for session_file in "$project_dir"/*.jsonl; do
    if [[ -f "$session_file" ]]; then
        ((sessions++))
        local session_entries
        session_entries=$(jq -s 'map(select(has("message") and .message.usage != null...))' "$session_file")
        all_entries_combined=$(echo "$all_entries_combined $session_entries" | jq -s 'add')
    fi
done

# Then aggregate across all sessions
messages=$(echo "$all_entries_combined" | jq 'length')
tokens_input=$(echo "$all_entries_combined" | jq 'group_by(.model) | map({key: .[0].model, value: map(.input | tonumber) | add}) | from_entries')
```

## Test Results

### Before Fixes
- Tests didn't compile
- Tool returned empty data

### After Fixes
- **17/18 tests passing** ✅
- Tool works correctly:

```bash
❯ tools/llm-usage/llm-usage --all | jq '{opencode: .opencode | {found, sessions, messages}, claude_code: .claude_code | {found, sessions, messages}}'
{
  "opencode": {
    "found": true,
    "sessions": 598,
    "messages": 8669
  },
  "claude_code": {
    "found": true,
    "sessions": 264,
    "messages": 3737
  }
}
```

## Known Issue

**Test:** `daily_usage_breakdown` (1 test failing)

**Problem:** Test uses OpenCode timestamp `1700000000000` (2023-11-14) but expects it to appear in date bucket `2026-01-20`. This appears to be a typo in the test itself.

**Expected Fix:** Update test to use timestamp `1768899600000` (2026-01-20) to match the Claude message date, or update the expected date to `2023-11-14`.

## Files Modified

1. `tools/llm-usage/llm-usage` - Main script with all bug fixes
2. `tools/llm-usage/cli-tests/src/lib.rs` - Made `dsl` module public
3. `tools/llm-usage/cli-tests/tests/all_mode.rs` - Fixed imports

## Key Learnings

1. **Shell glob limits:** When dealing with thousands of files, use `find` instead of glob patterns
2. **macOS symlinks:** Always canonicalize paths with `pwd -P` when comparing filesystem paths
3. **Aggregation patterns:** Collect all data first, then aggregate - don't overwrite in loops
4. **Fallback strategies:** When direct lookups fail, implement content-based search as fallback
