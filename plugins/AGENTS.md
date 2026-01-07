# Plugins Policy

This document defines policies for developing, versioning, and publishing Claude Code plugins in the agent-chisels repository.

## Plugin Version Policy

**Policy**: All new Claude Code plugins start at version **1.0.0**.

**Rationale**:
- Version `0.x.x` implies experimental or unstable status.
- By the time a plugin is ready for the repository, it has been tested and is production-ready.
- Starting at `1.0.0` signals maturity and provides clear communication to users.
- Follows semantic versioning conventions.

**Examples**:
- Initial release of `agent-tools` plugin: `1.0.0`
- Bug fix to `agent-tools`: `1.0.1`
- New feature in `agent-tools`: `1.1.0`
- Breaking changes to `agent-tools`: `2.0.0`

## Push-to-Publish Workflow

**Policy**: Publishing a plugin is accomplished by pushing to the remote repository (e.g., GitHub).

**Workflow**:
1. Develop plugins locally in `plugins/[plugin-name]/`, .e.g. by using `claude --plugin-dir $(pwd)/plugins/[plugin-name]`.
2. Test skills, commands, and agents thoroughly.
3. Update version in both:
   - `plugins/[plugin-name]/.claude-plugin/plugin.json`
   - `plugins/marketplace.json`
4. Commit changes:
5. Tag the release with name `release-[plugin-name]-[<new-version>]`
6. Push to remote:

Once pushed, the `plugins/marketplace.json` is published. Users can then:
- Add the marketplace: `/plugin marketplace add agent-chisels https://raw.githubusercontent.com/lhohan/agent-chisels/main/plugins/marketplace.json`
- Install plugins: `/plugin install [plugin-name]@agent-chisels`

**Key Points**:
- Plugin changes to the marketplace manifest (adding/removing plugins, version bumps) take effect when pushed.
- Existing installations remain functional even if the marketplace URL becomes unavailable, but users cannot update or reinstall without the URL.

## Plugin Development Guidelines

### Directory Structure

All plugins go in `plugins/[plugin-name]/`:

```
plugins/
├── marketplace.json           # Single source of truth for all published plugins
└── [plugin-name]/
    ├── .claude-plugin/
    │   └── plugin.json        # Plugin metadata (name, version, description)
    ├── skills/
    ├── commands/
    ├── agents/
    └── hooks/
```

### Naming Conventions

- **Plugin names**: kebab-case (e.g., `agent-tools`, `jujutsu-vcs`)
- **Skill names**: kebab-case (e.g., `skill-evaluator`, `code-reviewer`)
- **Skill files**: `SKILL.md` (uppercase, required)

## Skill development guide

When new Skills are added or updated run the `skill-evaluator` skill on the changed skill.


---

**Document Version**: 1.0.0  
**Related**: `docs/plugin-dev-guide.md`, `plugins/marketplace.json`
