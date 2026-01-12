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

### Automated Version Checking (Pre-Commit Hook)

**RECOMMENDED**: Install the pre-commit hook to automatically enforce version updates:

```bash
# For Git repositories
ln -sf ../../../../.claude/skills/verify-release-readiness/hooks/pre-commit .git/hooks/pre-commit

# For Jujutsu repositories
# Add to .jj/repo/config.toml:
# [hooks]
# pre-commit = ".claude/skills/verify-release-readiness/hooks/pre-commit"
```

Once installed, the hook will:
- ✅ Automatically detect skill changes before each commit
- ✅ Block commits if skill versions haven't been updated
- ✅ Provide clear instructions on which versions need updating
- ✅ Ensure you never forget to update versions

### Manual Verification (Before Publishing)

Before publishing or committing skills or plugins to the marketplace, use the internal `verify-release-readiness` skill:

1. Load the skill: it will detect changed skills since the last release (`main@origin`)
2. Review the report — skills with unchanged versions will be flagged
3. Manually update version numbers in SKILL.md frontmatter for flagged skills
4. Run verification scripts to ensure all skills pass validation
5. Commit and push to publish

The skill is located at `.claude/skills/verify-release-readiness/SKILL.md` and provides detailed step-by-step guidance.

**Note**: If you've installed the pre-commit hook, steps 1-3 will be enforced automatically during commits.
