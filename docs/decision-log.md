# Decision Log

Decisions are listed in reverse chronological order (most recent first).

### AC-005: Migrate JJ skills to agentfiles repository [Status: Implemented]

> **In the context of** maintaining reusable skills across multiple repositories,
> **facing** duplication between the agent-chisels and agentfiles repositories,
> **we decided** to move the canonical `detect-jujutsu` and `use-jujutsu` skills to the agentfiles repository (`agents/dotagents/.agents/skills/`),
> **to achieve** a single source of truth and simplify maintenance,
> **accepting** that the agent-chisels repository no longer bundles these skills and must reference them externally.

### AC-004: Introduce agentfiles/ for centralized multi-agent configuration management [Status: Proposed]

> **In the context of** managing configurations for multiple CLI agents (Claude Code, OpenCode, Mistral Vibe) in a single repository,
> **facing** the need to share skills, commands, agents, and prompts across different tools while deploying to their respective home directory locations,
> **we decided** to create an `agentfiles/` directory with shared artifacts and per-agent stow packages, moving skills from root `skills/` to `agentfiles/shared/skills/`,
> **to achieve** centralized configuration management with minimal duplication, GNU Stow-based deployment, and maintainable symlink architecture,
> **accepting** the need to update existing plugin symlinks, add mise-en-place tooling, and maintain a two-level symlink chain (home → agent-config → shared).

**Key architectural choices:**
- `agentfiles/shared/` becomes single source of truth for skills (replacing root `skills/`)
- Each agent (claude-code, opencode, mistral-vibe) is a stow package
- Two-level symlinks: `~/.claude/skills/x` → `agentfiles/claude-code/.claude/skills/x` → `agentfiles/shared/skills/x`
- `--no-folding` flag ensures stow creates individual symlinks, preserving existing content in target directories
- Plugins at root update symlinks to `../../agentfiles/shared/skills/`
- Existing `.claude/` kept as project-level config for this repo
- Mise tasks for stow deployment (`stow-all`, `stow-claude`, etc.)

### AC-003: Use imperative form for skill names [Status: Implemented]

> **In the context of** skills moving closer to or becoming commands,
> **facing** a mix of gerund form (`evaluating-skills`) and potential inconsistency with the documented anti-pattern guidance that recommends "imperative verb form like `process-pdfs`",
> **we decided** to rename all skills from gerund form to imperative form,
> **to achieve** consistency with the documented best practices and clear, action-oriented skill names,
> **accepting** that existing documentation and historical references may still use old names and will need updates over time.

| Old Name | New Name |
|----------|----------|
| `detecting-jujutsu` | `detect-jujutsu` |
| `using-jujutsu` | `use-jujutsu` |
| `evaluating-skills` | `evaluate-skills` |
| `writing-agents-files` | `write-agents-files` |
| `documenting-architectural-decisions` | `document-architectural-decisions` |

See [plugins/AGENTS.md](../plugins/AGENTS.md) for updated naming conventions.

### AC-002: Use `.claude/skills/` at project level for skill discovery and dog-fooding across different AI agents [Status: Implemented]

> **In the context of** AI coding agents needing to discover available skills within a project,
> **facing** the need for a standard location that works across multiple tools (OpenCode, Claude Code, etc.),
> **we decided** to use `.claude/skills/` at the project level as the skill discovery path,
> **to achieve** cross-tool compatibility and the ability to dogfood skills defined in the repository,
> **accepting** the need to maintain symlinks from `.claude/skills/` to the source `skills/` directory via an automated script.

### AC-001: Centralize skills at root level and symlink from plugins [Status: Implemented]

> **In the context of** a repository containing both plugin-dependent and independent skills,
> **facing** the need for better skill discoverability, tooling support (OpenCode), and reduced coupling between skills and plugins,
> **we decided** to move actual skill files to a root `skills/` directory and use relative symlinks in `plugins/`,
> **to achieve** improved discoverability, direct OpenCode integration, and easier skill reuse,
> **accepting** the need to manually maintain symlinks when adding new skills and potential platform-specific symlink issues.
