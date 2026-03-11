# Agent Chisels

> [!NOTE]
> This repository is part of my personal public learning journey. I'm building and experimenting with reusable AI skills, commands, and agents in the open. Expect ongoing evolution, experimentation, and refinement as I learn. Also, because it is public, I hope to bring some more structure to my own work in this crazy-fast evolving domain.

Reusable skills, commands, and agents for AI-assisted development.

- [Claude Code plugins](./plugins/README.md)
- [Available Skills](#available-skills)

## Available Skills

### Architecture
- [document-architectural-decisions](./agentfiles/shared/skills/document-architectural-decisions/SKILL.md) — Document and manage architectural decisions using ADRs. Supports Y-statement and traditional ADR formats. Use when creating, reviewing, or searching decision records.
- [modelling-c4-diagrams](./agentfiles/shared/skills/modelling-c4-diagrams/SKILL.md) — Use when creating, revising, or reviewing C4 architecture diagrams from a real codebase, especially when deciding system, container, and component boundaries or writing Structurizr DSL.

### Version Control
- [detect-jujutsu](./agentfiles/shared/skills/detect-jujutsu/SKILL.md) — Verify if the current repository uses Jujutsu (jj) instead of git. Use when confirming VCS state before operations.
- [use-jujutsu](./agentfiles/shared/skills/use-jujutsu/SKILL.md) — Detailed guidance on Jujutsu (jj) VCS operations including committing, pushing, searching history, and working with revisions/revsets.

### Agentic Quality Assurance
- [evaluate-skills](./agentfiles/shared/skills/evaluate-skills/SKILL.md) — Evaluate Claude Code skills against best practices for size, structure, examples, and prompt engineering. Use when reviewing skills for deployment, optimization, or standards compliance.
- [write-agents-files](./agentfiles/shared/skills/write-agents-files/SKILL.md) — Create and maintain effective AGENTS.md files. Use when setting up or improving agent instructions.


## Installation

### Claude Code Marketplace

```
/plugin marketplace add lhohan/agent-chisels
```

#### Enable plugins

```
/plugin install jj@agent-chisels
/plugin install document-architectural-decisions@agent-chisels
/plugin install agent-tools@agent-chisels
```

### Manually

To install only the skills, add the contents of `agentfiles/shared/skills/` to your `~/.claude/skills` (user level) or `.claude/skills` (project level). This will install skills for all CLI AI-agents supporting skills in `.claude`.

Alternatively, copy the skills to your CLI AI-agent's preferred location for skills.

For more on skills see [agentskills.io](https://agentskills.io) or [Claude Skills documentation](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview).
