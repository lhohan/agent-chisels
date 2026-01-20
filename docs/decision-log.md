# Decision Log

Decisions are listed in reverse chronological order (most recent first).

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

See [skills/AGENTS.md](./skills/AGENTS.md) for updated naming conventions.

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
