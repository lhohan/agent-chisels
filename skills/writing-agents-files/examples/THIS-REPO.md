# agent-chisels Repository AGENTS.md Example

Self-referential example: AGENTS.md for the agent-chisels repository itself.

```markdown
# agent-chisels

Repository of reusable Claude Code skills, plugins, commands, and agents for AI-assisted development.

## Repository Structure

- **skills/**: Source of truth for all skills (SKILL.md files)
- **plugins/**: Plugin compositions (symlinks to skills/)
- **.claude-plugin/marketplace.json**: Published plugins registry

## Development Workflow

1. Create skills in `skills/[skill-name]/SKILL.md`
2. Add symlinks in `plugins/[plugin-name]/skills/`
3. Test locally with `claude --plugin-dir ./plugins/[plugin-name]`
4. Run verification before publishing

## Feature Workflow

Step-by-step feature implementation:
1. Identify entry points and relevant files
2. Make a small plan (if non-trivial)
3. Implement and update/add tests
4. Run verification commands
5. Update gotchas/docs if new pitfalls discovered
6. Summarize changes and remaining risks

## Build

Commands to build the project:
```bash
# No build step for this repo
```

## Testing

Commands to run tests:
```bash
# No automated tests for this repo
```

## Helpful Tools (CLI + MCP)

Tools and servers the agent can use:

- **CLI tools**
  - Skill evaluation: Use `/evaluating-skills` on new/modified skills
  - Version check: Run `verify-release-readiness` skill
  - Validation scripts: Check that skills pass structure validation

- **MCP servers**
  - None configured (list yours here)

All skills must pass evaluation before publishing.

## Gotchas Codex

### Symlink Structure
- Skills live in `skills/` (source of truth)
- Plugins contain symlinks to `../../../skills/[skill-name]`
- Never edit skills through plugin symlinks (edit source)
- Added: 2025-01-10 (ADR: decision-log.md)

### Version Management
- New plugins start at 0.1.0
- Update both plugin.json AND marketplace.json
- Run verify-release-readiness before commits
- Added: 2025-01-08 (Plugin versioning policy)

### Skill Naming
- Use gerund form (processing-pdfs, not pdf-processor)
- Kebab-case for directories and names
- SKILL.md must be uppercase
- Added: 2025-01-05 (Naming conventions)

### Description Length
- Target 200 characters for descriptions
- Maximum 1024 characters (hard limit)
- Include WHAT and WHEN TO USE
- Added: 2025-01-15 (evaluating-skills feedback)

## Guidelines

For detailed guidelines, see:

- **Plugin Development**: [plugins/AGENTS.md](./plugins/AGENTS.md) - Standards and workflows
- **Repository Overview**: [AGENTS.md](./AGENTS.md) - General structure and principles
```

**Line count: ~70 lines**

## Why This Works

- Under 100 lines ✓
- Specific verification tools for this repo (evaluating-skills, verify-release-readiness) ✓
- Real gotchas from actual development (symlinks, versioning, naming) ✓
- Points to specialized AGENTS.md files (plugins/AGENTS.md) ✓
- Demonstrates self-application of the methodology
- Repository-specific workflows (skills → plugins → verification → publish)

## Self-Application Analysis

This example demonstrates the skill's own principles:

1. **Brevity**: ~70 lines, well under 100-line target
2. **Agentic loops**: Lists concrete verification tools (evaluating-skills, verify-release-readiness)
3. **Living gotchas**: Real issues from actual development with dates and sources
4. **Task-specific files**: References plugins/AGENTS.md for detailed plugin development

The gotchas are actual pain points from agent-chisels development, making this a real-world example rather than theoretical.
