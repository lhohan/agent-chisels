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
