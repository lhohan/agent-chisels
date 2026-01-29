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
