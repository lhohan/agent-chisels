# OpenCode JJ Plugin

**Priority**: Medium
**Status**: Planned

## Goal

Port the existing Claude Code JJ SessionStart hook to OpenCode, enabling automatic Jujutsu VCS detection and context injection.

## Background: OpenCode vs Claude Code Plugins

### Key Differences

| Aspect | Claude Code | OpenCode |
|--------|-------------|----------|
| Plugin format | JSON config + markdown skills | JavaScript/TypeScript modules |
| Skills format | `SKILL.md` with YAML frontmatter | Same (Anthropic spec compatible) |
| Hooks | Shell commands, 9 event types | JS functions, 25+ event types |
| Data modification | Read-only (observe/block) | Can mutate input/output |
| Distribution | Marketplace | npm packages or local dirs |

### Hook Mapping

| Claude Code | OpenCode | Notes |
|-------------|----------|-------|
| `SessionStart` | `session.created` | Session initialization |
| `SessionEnd` | `session.deleted` | Session termination |
| `PreToolUse` | `tool.execute.before` | Can modify input |
| `PostToolUse` | `tool.execute.after` | Can modify output |
| `PreCompact` | `experimental.session.compacting` | Context summarization |
| `Notification` | `tui.toast.show` | Display notifications |

### Context Injection Pattern

OpenCode uses synthetic message injection:
```typescript
await ctx.client.session.prompt({
  sessionId: session.id,
  content: CONTEXT,
  noReply: true,    // Don't trigger response
  synthetic: true   // Hidden from UI
})
```

## Directory Structure Decision

OpenCode plugins will live in a **separate root directory** from Claude Code plugins:

```
agent-chisels/
├── plugins/                    # Claude Code plugins (existing)
├── skills/                     # Shared skills (existing)
├── opencode-plugins/           # NEW: OpenCode plugins
│   └── jj/
│       └── plugin/
│           └── jj-vcs.ts
└── ...
```

This separation:
- Keeps Claude Code and OpenCode concerns isolated
- Allows independent versioning/distribution
- Makes it clear which platform each plugin targets
- Enables shared skills via symlinks or imports

## Current Claude Code Implementation

**Files:**
- `plugins/jj/hooks/hooks.json` - Hook configuration
- `plugins/jj/hooks-handlers/jj-reminder.sh` - Handler script
- `skills/detect-jujutsu/scripts/detect-jj.sh` - Detection logic

**Flow:**
1. SessionStart triggers `jj-reminder.sh`
2. Script calls `detect-jj.sh` (checks `.jj/`, `jj st`)
3. If jj detected, outputs JSON with `additionalContext`
4. Claude Code injects context into session

---

## Solution 1: TypeScript Plugin (Recommended)

**Approach:** Native OpenCode plugin using `session.created` hook with shell script reuse.

### Files to Create

```
opencode-plugins/
└── jj/
    ├── plugin/
    │   └── jj-vcs.ts          # Main plugin
    ├── package.json           # Dependencies (@opencode-ai/plugin)
    └── README.md              # Installation instructions
```

### Implementation

```typescript
// opencode-plugins/jj/plugin/jj-vcs.ts
import type { Plugin } from "@opencode-ai/plugin"
import { resolve, dirname } from "path"
import { fileURLToPath } from "url"

export const JJVCSPlugin: Plugin = async (ctx) => {
  const { $ } = ctx

  // Get path to shared detection script in skills/
  const __dirname = dirname(fileURLToPath(import.meta.url))
  const repoRoot = resolve(__dirname, "../../..")
  const detectScript = resolve(repoRoot, "skills/detect-jujutsu/scripts/detect-jj.sh")

  // Detection function (reuses existing shell script)
  async function detectJJ(): Promise<boolean> {
    try {
      await $`bash ${detectScript} --quiet`
      return true
    } catch {
      return false
    }
  }

  const CONTEXT = `**CRITICAL: Jujutsu (jj) repository detected.**

Always use \`jj\` commands for version control operations in this repository.

**Guidance**:
- If uncertain about VCS state, invoke the \`detect-jujutsu\` skill
- For detailed instructions, invoke the \`use-jujutsu\` skill
- Use \`/use-jj\` to re-inject this reminder

State the version control system you will use for this session.`

  return {
    "session.created": async (session) => {
      if (await detectJJ()) {
        // Inject context as synthetic message
        await ctx.client.session.prompt({
          sessionId: session.id,
          content: CONTEXT,
          noReply: true,
          synthetic: true
        })
      }
    },
    "session.compacted": async (session) => {
      // Re-inject after compaction
      if (await detectJJ()) {
        await ctx.client.session.prompt({
          sessionId: session.id,
          content: CONTEXT,
          noReply: true,
          synthetic: true
        })
      }
    }
  }
}
```

### Pros
- Direct equivalent to Claude Code hook behavior
- Reuses existing detection shell script
- Automatic context injection at session start
- Survives context compaction
- Clean TypeScript implementation

### Cons
- Requires OpenCode plugin infrastructure
- More code than Solution 2
- Needs testing with OpenCode SDK

---

## Solution 2: AGENTS.md with Dynamic Detection

**Approach:** Use OpenCode's `opencode.json` instructions field with conditional file generation.

### Files to Create

```
opencode-plugins/
└── jj/
    ├── scripts/
    │   └── generate-jj-context.sh  # Generates context file
    ├── opencode.json               # References generated file
    └── .opencode-jj-context.md     # Generated (gitignored)
```

### Implementation

**opencode.json:**
```json
{
  "instructions": [
    ".opencode-jj-context.md"
  ]
}
```

**generate-jj-context.sh:**
```bash
#!/bin/bash
# Run at session start (manually or via wrapper)

SCRIPT_DIR="$(dirname "$0")"
OUTPUT_FILE="${SCRIPT_DIR}/../../.opencode-jj-context.md"

if bash "${SCRIPT_DIR}/../../../skills/detect-jujutsu/scripts/detect-jj.sh" --quiet; then
  cat > "$OUTPUT_FILE" << 'EOF'
# Jujutsu VCS Context

**CRITICAL: Jujutsu (jj) repository detected.**

Always use `jj` commands for version control operations.

**Guidance**:
- If uncertain about VCS state, invoke the `detect-jujutsu` skill
- For detailed instructions, invoke the `use-jujutsu` skill
EOF
else
  # Empty file when not jj repo
  echo "" > "$OUTPUT_FILE"
fi
```

### Pros
- Simpler implementation
- No TypeScript required
- Uses existing OpenCode instructions system

### Cons
- Requires manual script execution before starting OpenCode
- File persists between sessions (stale state risk)
- Doesn't auto-reinject after compaction
- Less elegant (file generation hack)

---

## Recommendation

**Solution 1 (TypeScript Plugin)** is recommended because:

1. **Direct parity** with Claude Code behavior
2. **Automatic** - no manual steps required
3. **Compaction resilience** - re-injects context when needed
4. **Clean architecture** - proper plugin, not file generation hack
5. **Reuses existing scripts** - shared detection logic

---

## Implementation Steps

1. Create directory structure:
   ```
   mkdir -p opencode-plugins/jj/plugin
   ```

2. Initialize package.json:
   ```bash
   cd opencode-plugins/jj
   npm init -y
   npm install --save-dev @opencode-ai/plugin
   ```

3. Create plugin file:
   - `opencode-plugins/jj/plugin/jj-vcs.ts`
   - Implement `session.created` and `session.compacted` hooks
   - Use `$` API to call existing `detect-jj.sh` script

4. Update documentation:
   - Create `opencode-plugins/README.md` explaining the structure
   - Create `opencode-plugins/jj/README.md` with install instructions

5. Update AGENTS.md:
   - Document new `opencode-plugins/` directory
   - Explain relationship to Claude Code plugins

---

## Verification

1. **Install the plugin:**
   ```bash
   # Symlink to OpenCode plugin directory
   ln -s /path/to/agent-chisels/opencode-plugins/jj ~/.config/opencode/plugin/jj
   ```

2. **Manual test in jj repo:**
   ```bash
   cd /path/to/jj-repo
   opencode
   # Should see JJ context injected automatically
   ```

3. **Non-jj repo test:**
   ```bash
   cd /path/to/git-only-repo
   opencode
   # Should NOT see JJ context
   ```

4. **Compaction test:**
   - Have a long conversation until compaction triggers
   - Verify JJ context is re-injected

---

## Files to Modify/Create

| File | Action |
|------|--------|
| `opencode-plugins/jj/plugin/jj-vcs.ts` | Create |
| `opencode-plugins/jj/package.json` | Create |
| `opencode-plugins/jj/README.md` | Create |
| `opencode-plugins/README.md` | Create |
| `AGENTS.md` | Update (add opencode-plugins section) |

## References

- [OpenCode Plugins Documentation](https://opencode.ai/docs/plugins/)
- [opencode-skillful GitHub](https://github.com/zenobi-us/opencode-skillful)
- [Superpowers for OpenCode](https://blog.fsck.com/2025/11/24/Superpowers-for-OpenCode/)
- [opencode-agent-skills](https://github.com/joshuadavidthomas/opencode-agent-skills)
