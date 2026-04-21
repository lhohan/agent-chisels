#!/bin/bash

# Jujutsu (jj) SessionStart hook handler.
# Performs inline detection; skills are maintained externally in agentfiles.

# 1. Authoritative detection (root-aware)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if ! command -v jj >/dev/null 2>&1; then
  exit 0
fi
if ! (cd "$REPO_ROOT" && jj st --no-pager --color=never >/dev/null 2>&1); then
  exit 0
fi

# 2. Construct concise reminder
CONTEXT="**CRITICAL: Jujutsu (jj) repository detected.**

Always use \`jj\` commands for version control operations in this repository.

**Guidance**:
- If you are uncertain about the VCS state (e.g. cwd changed), invoke the \`detect-jujutsu\` skill.
- For detailed instructions and best practices, invoke the \`use-jujutsu\` skill.
- Use \`/use-jj\` to re-inject this reminder.

State the version control system you will be using for this session."

# 3. JSON Escaping
ESCAPED_CONTEXT=$(echo "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g; s/	/\\t/g' | tr -d '\n')

# 4. Output JSON for Claude Code
echo "{
  \"hookSpecificOutput\": {
    \"hookEventName\": \"SessionStart\",
    \"additionalContext\": \"$ESCAPED_CONTEXT\"
  }
}"
exit 0
