# Agent Guidelines for agent-chisels

This document provides general guidelines for the agent-chisels repository and points to specialized documentation for specific areas.

## Repository Overview

**agent-chisels** is a repository containing reusable skills, commands, and agents for AI-assisted development.

The repository is organized as follows:

- **agentfiles/**: Shared skills, commands, agents, prompts + per-agent Stow packages
- **plugins/**: Claude Code plugins that compose skills, commands, and agents
- **docs/**: General documentation and guides
- **backlog/**: Future work and planned features

## Directory Structure

```
agent-chisels/
├── AGENTS.md                    # This file (general guidelines)
├── .claude-plugin/
│   └── marketplace.json         # Published plugins registry
├── .claude/
│   └── skills/                  # Project-level skills (internal use)
├── agentfiles/                  # Shared artifacts + agent Stow packages
│   ├── shared/
│   │   ├── skills/              # Reusable AI skills (source of truth)
│   │   ├── commands/
│   │   ├── agents/
│   │   └── prompts/
│   ├── claude-code/             # Stow package for ~/.claude/
│   ├── opencode/                # Stow package for ~/.config/opencode/
│   └── mistral-vibe/            # Stow package for ~/.vibe/
├── plugins/                     # Claude Code plugins
│   ├── AGENTS.md                # Plugin development guide (detailed)
│   └── [plugin-name]/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/              # Symlinks to shared skills
│       ├── commands/
│       ├── agents/
│       └── hooks/
├── docs/                        # Documentation
└── backlog/                     # Future work
```

## Plugin and Skill Development

**All guidelines for developing, naming, publishing, and quality-assuring plugins and skills are in [plugins/AGENTS.md](./plugins/AGENTS.md).**

Refer to that document for:
- Plugin and skill structure and naming conventions
- Detailed skill development standards (frontmatter, organization, size, scope, examples)
- Quality assurance with `evaluate-skills`
- Version management and publishing workflows
- Marketplace distribution

## Release Workflow

Before publishing or committing skills or plugins to the marketplace, use the internal `verify-release-readiness` skill:

1. Load the skill: it will detect changed skills since the last release (`main@origin`)
2. Review the report — skills with unchanged versions will be flagged
3. Manually update version numbers in SKILL.md frontmatter for flagged skills
4. Run verification scripts to ensure all skills pass validation
5. Commit and push to publish

The skill is located at `.claude/skills/verify-release-readiness/SKILL.md` and provides detailed step-by-step guidance.

## Landing the Plane (Task Closure + Handoff)

**Trigger this workflow before any `bd close` and before any final completion handoff.** Push to remote is optional unless explicitly requested.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
   - Review scope first: `jj diff --no-pager`
   - Run the task-relevant verification commands (for example `just test`, `just check`, language-specific tests/linters/build)
   - Run a full code review.
3. **Update issue status** - Close finished work, update in-progress items
   - Do NOT close a task if any required quality gate is failing
   - Commit changes relasted to this task with a clear commit message. The body should contain the task id the commit solves.
4. **Optional Remote Sync** - Push only when requested:
   ```bash
   bd sync
   jj git push
   jj st --no-pager  # MUST show clean working copy / synced state
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All required changes committed.
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Never close tasks with failing tests/checks/builds
- If a push is requested and it fails, resolve and retry until it succeeds


<!-- BEGIN BEADS INTEGRATION v:1 profile:full hash:d4f96305 -->
## Issue Tracking with bd (beads)

**IMPORTANT**: This project uses **bd (beads)** for ALL issue tracking. Do NOT use markdown TODOs, task lists, or other tracking methods.

### Why bd?

- Dependency-aware: Track blockers and relationships between issues
- Git-friendly: Dolt-powered version control with native sync
- Agent-optimized: JSON output, ready work detection, discovered-from links
- Prevents duplicate tracking systems and confusion

### Quick Start

**Check for ready work:**

```bash
bd ready --json
```

**Create new issues:**

```bash
bd create "Issue title" --description="Detailed context" -t bug|feature|task -p 0-4 --json
bd create "Issue title" --description="What this issue is about" -p 1 --deps discovered-from:bd-123 --json
```

**Claim and update:**

```bash
bd update <id> --claim --json
bd update bd-42 --priority 1 --json
```

**Complete work:**

```bash
bd close bd-42 --reason "Completed" --json
```

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Workflow for AI Agents

1. **Check ready work**: `bd ready` shows unblocked issues
2. **Claim your task atomically**: `bd update <id> --claim`
3. **Work on it**: Implement, test, document
4. **Discover new work?** Create linked issue:
   - `bd create "Found bug" --description="Details about what was found" -p 1 --deps discovered-from:<parent-id>`
5. **Complete**: `bd close <id> --reason "Done"`

### Auto-Sync

bd automatically syncs via Dolt:

- Each write auto-commits to Dolt history
- Use `bd dolt push`/`bd dolt pull` for remote sync
- No manual export/import needed!

### Important Rules

- ✅ Use bd for ALL task tracking
- ✅ Always use `--json` flag for programmatic use
- ✅ Link discovered work with `discovered-from` dependencies
- ✅ Check `bd ready` before asking "what should I work on?"
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT use external issue trackers
- ❌ Do NOT duplicate tracking systems

For more details, see README.md and docs/QUICKSTART.md.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

<!-- END BEADS INTEGRATION -->
