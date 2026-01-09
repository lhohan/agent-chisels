#!/bin/bash

# Jujutsu (jj) SessionStart hook handler.
# Uses shared detection script to gate context injection.

# 1. Authoritative detection (root-aware)
if ! bash "${CLAUDE_PLUGIN_ROOT}/scripts/detect-jj.sh" --quiet; then
  exit 0
fi

# 2. Construct concise reminder
CONTEXT="**CRITICAL: Jujutsu (jj) repository detected.**

Always use \`jj\` commands for version control operations in this repository. 

**Guidance**:
- If you are uncertain about the VCS state (e.g. cwd changed), invoke the \`detecting-jujutsu\` skill.
- For detailed instructions and best practices, invoke the \`using-jujutsu\` skill.
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
