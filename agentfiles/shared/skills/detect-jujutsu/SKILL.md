---
name: detect-jujutsu
description: Use at session start or before the first version control action to detect whether the repository should be operated with Git or Jujutsu (jj).
version: 0.5.0
---

# Detecting Jujutsu (jj)

This skill determines whether the current repository uses Jujutsu (jj). Use the detection ladder in order.

Trigger cues: user asks to run version control actions (for example status, diff, log, commit, amend, push, branch, rebase) where both `git` and `jj` may be available.

If `jj` is available in the current repo, prefer `jj` as the default VCS for this session unless the user or project policy explicitly asks for `git`.

## Detection Ladder

**Stop at the first successful detection.**

### Step 1: Try `jj st` (fast path)

```bash
jj st --no-pager
```

- **Exit 0** → JJ repo. Use `jj` commands. Invoke `use-jujutsu` skill. **STOP HERE.**
- **Blocked by tool policy** → Proceed to Step 3 (do not attempt Step 2).
- **Exit non-zero** → Proceed to Step 2.

### Step 2: Run detection script (authoritative)

The script is embedded inline to work across multiple coding agents regardless of where skills are installed.

```bash
cat > /tmp/detect-jj.sh << 'SCRIPT_EOF'
#!/bin/bash

# Embedded inline for cross-agent compatibility.
# Shared Jujutsu (jj) detection script
# Authoritative check for JJ repository status, root-aware.

QUIET=false
if [ "$1" == "--quiet" ]; then
  QUIET=true
fi

log() {
  if [ "$QUIET" = false ]; then
    echo "$1"
  fi
}

# 1. Determine repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  log "Error: Not inside a git repository (git rev-parse failed)."
  log "Next steps: cd into a repository or run 'git status' to confirm environment."
  exit 2
fi

# 2. Check for jj command
if ! command -v jj >/dev/null 2>&1; then
  if [ -d "$REPO_ROOT/.jj" ]; then
    log "Hint: .jj directory found at repo root ($REPO_ROOT), but 'jj' command is missing."
    log "Next steps: Install Jujutsu (https://martinvonz.github.io/jj/) to work with this repository."
  else
    log "No Jujutsu detected: 'jj' command missing and no .jj directory at root."
  fi
  exit 2
fi

# 3. Authoritative check: jj status at root
if (cd "$REPO_ROOT" && jj st --no-pager --color=never >/dev/null 2>&1); then
  log "Jujutsu detected: 'jj status' succeeded at repo root ($REPO_ROOT)."
  log "Next steps: Use 'jj' commands for version control; consult 'use-jujutsu' skill for guidance."
  exit 0
else
  # Check if it was just "not a jj repo" or some other error
  if [ -d "$REPO_ROOT/.jj" ]; then
     log "Warning: .jj directory exists at root, but 'jj status' failed."
     log "Next steps: Check 'jj status' manually for specific errors (e.g. corruption or version mismatch)."
     exit 2
  else
     log "No Jujutsu detected: 'jj status' failed and no .jj directory found at root."
     log "Next steps: Use git workflows for this repository."
     exit 1
  fi
fi
SCRIPT_EOF

bash /tmp/detect-jj.sh
```

- **Exit 0** → JJ repo. Use `jj` commands. Invoke `use-jujutsu` skill. **STOP HERE.**
- **Exit 1** → Git repo (not JJ). Use standard `git` workflows. **STOP HERE.**
- **Exit 2** → Indeterminate. Proceed to Step 3.
- **Blocked by tool policy** → Proceed to Step 3.

### Step 3: Check for `.jj/` directory (fallback - no Bash required)

**Use this when Bash commands are restricted or previous steps failed.**

Use the Read or Glob tool (not Bash) to check for `.jj/` directory:

Determine repo root using Read on current directory or known paths:
   ```
   Read: <repo-root>/.jj
   ```

- **`.jj/` found** → JJ repo. Use `jj` commands. Invoke `use-jujutsu` skill. **STOP HERE.**
- **Not found** → Assume Git. Use standard `git` workflows. **STOP HERE.**
- **Cannot determine** → Ask user: "Cannot detect version control system. Is this a Jujutsu (jj) or Git repository?"

## Handling Tool Restrictions

**If you receive a tool policy error when running Bash:**

1. Immediately switch to Step 3 (do not retry Bash commands).
2. Use Read/Glob tools only - these typically have fewer restrictions.
3. If still blocked, ask the user directly.

## Outcome

- **JJ confirmed:** Use `jj` commands. Invoke `use-jujutsu` skill.
- **Git:** Use standard `git` workflows.
- **Uncertain:** State uncertainty and ask user which VCS to use.
