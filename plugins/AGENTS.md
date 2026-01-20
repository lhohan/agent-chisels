# Plugin Development Guide

This document defines policies, guidelines, and best practices for developing, versioning, and publishing Claude Code plugins in the agent-chisels repository.

## Plugin Development Guidelines

### Directory Structure

All plugins go in `plugins/[plugin-name]/`:

```
plugins/
└── [plugin-name]/
    ├── .claude-plugin/
    │   └── plugin.json        # Plugin metadata (name only)
    ├── skills/                # Symlinks to ../../skills/[skill-name]
    ├── commands/
    ├── agents/
    └── hooks/
```

At the root-level of repository:
```
├── .claude-plugin/
│   └── marketplace.json       # Single source of truth for all published plugins
```

### Naming Conventions

- **Plugin names**: kebab-case (e.g., `agent-tools`, `jj`)
- **Skill names**: kebab-case (e.g., `evaluate-skills`, `code-reviewer`)
- **Skill files**: `SKILL.md` (uppercase, required)

## Architecture

To understand _why_ the plugins in this directory are setup: ./decision-log.md may provide context.

When decisions are made they should be evaluated against the existing decisions in ./decision-log.md . 

Decisions should be updated so the decision log and implementation stay consistent at all times.

## Plugin Version Policy

**Policy**: All new Claude Code plugins start at version **0.1.0**.

**Rationale**:
- Version `0.x.x` implies experimental or unstable status.
-   However, by the time a plugin is ready for the repository, it has been tested and successfully used in projects.
- Starting at `1.0.0` signals maturity and provides clear communication to users.
- Follows semantic versioning conventions.

**Examples**:
- Initial release of `agent-tools` plugin: `0.1.0`
- Bug fix to `agent-tools`: `0.1.1`
- New feature in `agent-tools`: `0.2.0`
- First stable release of `agent-tools`: `1.0.0`
- Breaking changes to `agent-tools`: `2.0.0`

## Plugin Publishing Workflow

**Policy**: Publishing a plugin is accomplished by pushing to the remote repository (e.g., GitHub).

### Publishing Steps

1. **Develop locally**:
   ```bash
   claude --plugin-dir ./plugins/[plugin-name]
   ```

2. **Test thoroughly**: 
   - Use the `evaluate-skills` skill for all skills
   - Test commands and agents as applicable

3. **Update documentation**:
    - Add new skills to `skills/README.md` with name and concise description (1-3 sentences max)
    - Update plugin-to-skill mapping in `plugins/README.md`
    - Update versions in both:
      - `plugins/[plugin-name]/.claude-plugin/plugin.json`
      - `.claude-plugin/marketplace.json` (at root)

4. **Commit changes**:
5. **Tag the release**:
6. **Push to remote**:

### Marketplace Distribution

Once pushed, the `.claude-plugin/marketplace.json` is published users can add the marketplace `/plugin marketplace add lhohan/agent-chisels` and install plugins: `/plugin install [plugin-name]@agent-chisels`

**Key Points**:
- Plugin changes to the marketplace manifest (adding/removing plugins, version bumps) take effect when pushed.
- Existing installations remain functional even if the marketplace URL becomes unavailable, but users cannot update or reinstall without the URL.

## Plugin Metadata Strategy

**Policy**: Use `marketplace.json` as the authoritative source for all plugin distribution metadata.

- `marketplace.json`: Contains all distribution metadata (version, description, category, keywords)
- `plugin.json`: Minimal file containing only the `name` field (required for local `--plugin-dir` development)

For details on this decision, see [decision-log.md](./decision-log.md).

## Key Principles

1. **Quality First**: Use `evaluate-skills` before publishing
2. **Clear Scope**: Each skill has one focused capability
3. **User-Centric**: Write for discoverability and ease of use
4. **Semantic Versioning**: Follow version conventions
5. **Documentation**: Comprehensive examples and guidelines
6. **Consistency**: Follow naming and structure conventions
