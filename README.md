# Agent Chisels

> [!NOTE]
> This repository is part of my personal public learning journey. I'm building and experimenting with reusable AI skills, commands, and agents in the open. Expect ongoing evolution, experimentation, and refinement as I learn.

Reusable skills, commands, and agents for AI-assisted development.

- [Claude Code plugins](./plugins/README.md)
- [Available Skills](#available-skills)

## Available Skills

### Architecture
- [documenting-architectural-decisions](./skills/documenting-architectural-decisions/SKILL.md) — Document and manage architectural decisions using ADRs. Supports Y-statement and traditional ADR formats. Use when creating, reviewing, or searching decision records.

### Version Control
- [detecting-jujutsu](./skills/detecting-jujutsu/SKILL.md) — Verify if the current repository uses Jujutsu (jj) instead of git. Use when confirming VCS state before operations.
- [using-jujutsu](./skills/using-jujutsu/SKILL.md) — Detailed guidance on Jujutsu (jj) VCS operations including committing, pushing, searching history, and working with revisions/revsets.

### Agentic Quality Assurance
- [evaluating-skills](./skills/evaluating-skills/SKILL.md) — Evaluate Claude Code skills against best practices for size, structure, examples, and prompt engineering. Use when reviewing skills for deployment, optimization, or standards compliance.


## Installation

### Claude Code Marketplace

```
/plugin marketplace add lhohan/agent-chisels
```

#### Enable plugins

```
/plugin install jj@agent-chisels
/plugin install documenting-architecture-decisions@agent-chisels
/plugin install agent-tools@agent-chisels
```

### Manually

To install only the skills, add the contents of the `skills` directory to your `~/.claude/skills` (user level) or `.claude/skills` (project level). This will install skills for all CLI AI-agents supporting skills in `.claude`.

Alternatively, copy the skills to your CLI AI-agent's preferred location for skills.

For more on skills see [agentskills.io](https://agentskills.io) or [Claude Skills documentation](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview).
