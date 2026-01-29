#!/bin/bash

# Shared Jujutsu (jj) detection script for agent-chisels plugin.
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
  log "Next steps: Use 'jj' commands for version control; consult 'using-jujutsu' skill for guidance."
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
