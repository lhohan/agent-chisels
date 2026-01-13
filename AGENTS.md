# Agent Guidelines for agent-chisels

This document provides general guidelines for the agent-chisels repository and points to specialized documentation for specific areas.

## Repository Overview

**agent-chisels** is a repository containing reusable skills, commands, and agents for AI-assisted development.

The repository is organized as follows:

- **skills/**: Reusable AI skills (source of truth)
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
├── skills/                      # Reusable AI skills (source of truth)
│   └── [skill-name]/
│       ├── SKILL.md             # Skill definition
│       └── examples/            # Example files
├── plugins/                     # Claude Code plugins
│   ├── AGENTS.md                # Plugin development guide (detailed)
│   └── [plugin-name]/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/              # Symlinks to ../../skills/[skill-name]
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
- Quality assurance with `evaluating-skills`
- Version management and publishing workflows
- Marketplace distribution

## Release Workflow

### Automated Version Checking (Pre-Push Hook)

**RECOMMENDED**: Install the pre-push hook to automatically enforce version updates:

```bash
# For both Git and Jujutsu repositories
ln -sf ../../../../.claude/skills/verify-release-readiness/hooks/pre-push .git/hooks/pre-push
```

Once installed, the hook will:
- ✅ Automatically detect skill changes before each push
- ✅ Block pushes if skill versions haven't been updated
- ✅ Provide clear instructions on which versions need updating
- ✅ Works for both Git (`git push`) and Jujutsu (`jj git push`) users
- ✅ Ensures you never publish skills with incorrect versions

**Why pre-push?** Unlike pre-commit hooks, pre-push works automatically for both Git and Jujutsu with a single installation. Jujutsu users run `jj git push`, which triggers Git's pre-push hook automatically.

**Alternative:** A pre-commit hook is also available at `hooks/pre-commit` if you prefer earlier validation (but requires separate Jujutsu configuration).

### Manual Verification (Before Publishing)

Before publishing or committing skills or plugins to the marketplace, use the internal `verify-release-readiness` skill:

1. Load the skill: it will detect changed skills since the last release (`main@origin`)
2. Review the report — skills with unchanged versions will be flagged
3. Manually update version numbers in SKILL.md frontmatter for flagged skills
4. Run verification scripts to ensure all skills pass validation
5. Commit and push to publish

The skill is located at `.claude/skills/verify-release-readiness/SKILL.md` and provides detailed step-by-step guidance.

**Note**: If you've installed the pre-push hook, version checking will be enforced automatically during pushes.
