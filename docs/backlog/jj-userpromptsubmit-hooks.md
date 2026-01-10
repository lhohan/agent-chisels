# UserPromptSubmit Hooks for jj Reminder

**Priority**: Low
**Status**: Deferred (see JJ-006)

## Problem

The current `SessionStart` hook fires once per session. In long sessions, Claude may "forget" to use jj commands instead of git, requiring manual `/use-jj` invocation.

## Research Findings

### Hook Options Comparison

| Hook | Frequency | Overhead | Timing |
|------|-----------|----------|--------|
| SessionStart | Once/session | ~50ms once | Before any prompts |
| UserPromptSubmit (wildcard) | Every prompt | ~50ms + ~80 tokens/prompt | Before Claude thinks |
| UserPromptSubmit (VCS matcher) | VCS prompts only | Same, but less frequent | Before Claude thinks |
| PreToolUse (Bash) | Every bash call | ~50ms/call | Too late (decision already made) |

### Overhead Estimates

- Command hook execution: ~10-50ms (shell script)
- jj detection (`jj st --no-pager`): ~20-50ms
- Token overhead per injection: ~50-100 tokens

### Potential Solution: VCS Keyword Matcher

Use `UserPromptSubmit` with a matcher that only fires on VCS-related prompts:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "commit|push|pull|branch|status|log|diff|merge|rebase|checkout|stash|bookmark|jj|history",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks-handlers/jj-reminder.sh"
          }
        ]
      }
    ]
  }
}
```

**Advantages**:
- Fires only on VCS-relevant prompts
- Still early enough to influence Claude's decision
- Minimal overhead for non-VCS work

**Disadvantages**:
- Won't catch implicit VCS needs (e.g., "save my changes")
- Matcher may need tuning
- Adds complexity vs current simple approach

### Script Changes Required

If implementing, `jj-reminder.sh` needs:
1. Change `hookEventName` from `"SessionStart"` to `"UserPromptSubmit"`
2. Shorten message for repeated use

## Decision

Deferred in favor of simplicity. Current `SessionStart` + manual `/use-jj` approach is sufficient.

See: `plugins/jj/decision-log.md` (JJ-006)

## References

- Claude Code hooks documentation
- Context7 research on hook event types
