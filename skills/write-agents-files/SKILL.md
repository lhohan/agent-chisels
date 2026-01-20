---
name: write-agents-files
description: Create and maintain effective AGENTS.md files following OpenAI best practices. Keep instructions brief, unlock agentic loops, document gotchas, and reference task-specific files. Use when setting up or improving agent instructions.
version: "0.1.0"
---

# Writing Effective AGENTS.md Files

Create and maintain high-quality AGENTS.md instruction files for AI coding agents following proven best practices from OpenAI and industry leaders.

## Table of Contents

- [Common Sections in AGENTS.md](#common-sections-in-agentsmd)
- [Instructions](#instructions)
  - [1. Understand Context](#1-understand-context)
  - [2. Draft Core Instructions](#2-draft-core-instructions)
  - [3. Add Agentic Loop Tools](#3-add-agentic-loop-tools)
  - [4. Create Gotchas Section](#4-create-gotchas-section)
  - [5. Reference Task-Specific Files](#5-reference-task-specific-files)
  - [6. Validate Against Best Practices](#6-validate-against-best-practices)
- [Best Practices](#best-practices)
- [Examples](#examples)
- [Requirements](#requirements)
- [See Also](#see-also)

## Common Sections in AGENTS.md

Based on OpenAI best practices, effective AGENTS.md files typically include these common sections:

1. **Project overview and structure** - Brief description and key directories
2. **Build and test commands** - Concrete verification commands
3. **Helpful CLI tools and MCP servers** - Tools and servers the agent can use
4. **Workflow for implementing a feature** - Step-by-step feature implementation
5. **Pointers to task-specific guidance** - Links to specialized documentation

## Instructions

### 1. Understand Context

Before creating or updating an AGENTS.md file:

**Gather information:**
- Ask the user about their project type (web app, CLI tool, library, etc.)
- Identify key workflows (testing, building, deploying)
- Determine what tools the agent should use (linters, test runners, formatters)
- Understand common mistakes or gotchas in their codebase

**Read existing context:**
- Check for existing AGENTS.md, README.md, or CONTRIBUTING.md files
- Scan recent commit messages for patterns
- Review test and build scripts

### 2. Draft Core Instructions

**Keep it brief and focused:**
- Target: Under 100 lines for main AGENTS.md (most OpenAI AGENTS.md files are under 100 lines)
- Use clear, imperative language (verb-first)
- Focus on WHAT and WHY, not HOW (agents are smart enough)
- Avoid over-explaining concepts the agent already knows

**Structure:**
```markdown
# Project Name

Brief 1-2 sentence project description.

## Project Overview

Brief description of the project purpose and scope.

## Repository Structure

Key directories and files:
- `src/` - Source code
- `tests/` - Test files
- `docs/` - Documentation
- `config/` - Configuration files

## Build

Commands to build the project:
```bash
npm run build
```

## Testing

Commands to run tests:
```bash
npm test
```

## Helpful Tools (CLI + MCP)

Tools and servers the agent can use:

- **CLI tools**
  - Linter: `npm run lint`
  - Type checker: `npm run typecheck`
  - Test runner: `npm test`
  - Build tool: `npm run build`

- **MCP servers**
  - List the MCP servers available in your environment
  - Include what each is for and when to use it

## Feature Workflow

Step-by-step feature implementation:
1. Identify entry points and relevant files
2. Make a small plan (if non-trivial)
3. Implement and update/add tests
4. Run verification commands
5. Update gotchas/docs if new pitfalls discovered
6. Summarize changes and remaining risks

## Gotchas Codex

[See Gotchas section below]

## Detailed Guidelines

For specific workflows, see:
- **Architecture**: [ARCHITECTURE.md](./ARCHITECTURE.md)
- **API Design**: [API.md](./API.md)
- **Testing**: [TESTING.md](./TESTING.md)
```

**Example brief instruction:**
```markdown
## Testing

Run the full test suite before committing:
```bash
npm test
```

Fix any failing tests immediately. Do not commit failing tests.
```

### 3. Add Agentic Loop Tools

**Unlock agentic loops** by explicitly listing tools the agent can call to verify its own work.

**Common verification tools:**
- **Linters**: ESLint, Pylint, Ruff, Clippy
- **Formatters**: Prettier, Black, rustfmt
- **Type checkers**: TypeScript, mypy, pyright
- **Test runners**: Jest, pytest, cargo test
- **Build tools**: npm run build, cargo build, make
- **Git hooks**: pre-commit, husky

**Template:**
```markdown
## Build

Commands to build the project:
```bash
npm run build
```

## Testing

Commands to run tests:
```bash
npm test
```

## Helpful Tools (CLI + MCP)

Tools and servers the agent can use:

- **CLI tools**
  - Linter: `npm run lint` - Check code style and catch errors
  - Type checker: `npm run typecheck` - Verify type safety
  - Tests: `npm test` - Run full test suite
  - Build: `npm run build` - Ensure production build succeeds

- **MCP servers**
  - List the MCP servers available in your environment
  - Include what each is for and when to use it
  - Example: Context7 for library API lookups, Exa for code context
```

**Key principle:** Show the agent what success looks like by listing concrete verification commands.

### 4. Create Gotchas Section

**Continuously update with real mistakes.** Maintain a living "Gotchas Codex" section that evolves through:
- Pull request reviews
- Production incidents
- Repeated mistakes by the agent or team

**Format:**
```markdown
## Gotchas Codex

Common mistakes to avoid (updated from real issues):

### API Rate Limits
- The external API has a 100 req/min limit
- Always implement exponential backoff
- Cache responses when possible
- Added: 2025-01-15 (PR #123)

### Database Migrations
- Never auto-generate migration names
- Use descriptive names: `YYYY-MM-DD-description.sql`
- Test rollback before deploying
- Added: 2025-01-10 (Incident #456)

### Test Flakiness
- Tests depending on `Date.now()` are flaky
- Use `jest.useFakeTimers()` for time-dependent tests
- Added: 2025-01-08 (PR #789)
```

**Update protocol:**
- Add new gotchas with date and source (PR number, issue, incident)
- Keep gotchas specific and actionable
- Remove resolved gotchas (if root cause is fixed)
- Review quarterly to keep relevant

### 5. Reference Task-Specific Files

**Point to task-specific .md files** instead of bloating the main AGENTS.md.

**Common specialized files:**
- **PLANS.md**: Design and iteration guidelines before implementation
- **ARCHITECTURE.md**: System design, component relationships
- **API.md**: API design standards and patterns
- **TESTING.md**: Detailed testing strategies and patterns
- **DEPLOYMENT.md**: Release and deployment procedures
- **CONTRIBUTING.md**: Contribution guidelines

**Reference format:**
```markdown
# Project Name

Core instructions here (keep under 100 lines).

## Detailed Guidelines

For specific workflows, see:

- **Planning**: [PLANS.md](./PLANS.md) - Design iteration process
- **Architecture**: [ARCHITECTURE.md](./ARCHITECTURE.md) - System overview
- **Testing**: [TESTING.md](./TESTING.md) - Testing standards
- **API Design**: [API.md](./API.md) - API conventions

Consult these files before starting complex work.
```

**When to split:**
- Main AGENTS.md approaching 100 lines → Extract details to specialized files
- Complex domain-specific rules → Create dedicated .md file
- Lengthy examples or templates → Move to examples directory

### 6. Validate Against Best Practices

**Before finalizing, check:**

✓ **Brevity**: Under 100 lines for main AGENTS.md?
✓ **Agentic loops**: Are verification tools listed with commands?
✓ **Gotchas**: Is there a living section for real mistakes?
✓ **References**: Are specialized topics in separate .md files?
✓ **Clarity**: Can a new agent understand instructions immediately?
✓ **Actionability**: Are all instructions concrete and executable?
✓ **Common sections**: Does it include project overview, build/test, tools (CLI+MCP), feature workflow?

**Ask the user:**
- "What verification tools should the agent run?"
- "What are the most common mistakes in this codebase?"
- "Are there complex workflows that need separate documentation?"
- "What MCP servers are available for this project?"

## Best Practices

### Keep It Brief

- Most OpenAI AGENTS.md files are under 100 lines
- Too many instructions confuse the coding agent
- Extract detailed guidelines to separate files
- Trust the agent's base knowledge

**Common Mistakes to Avoid:**
- ❌ Don't write 500-line AGENTS.md files (defeats the purpose of brevity)
- ❌ Don't skip the verification tools section (prevents agentic loops)
- ❌ Don't use vague gotchas like "be careful with API" (be specific with limits and solutions)
- ❌ Don't embed lengthy examples in AGENTS.md (move to separate files)

### Unlock Agentic Loops

- Show the agent tools to verify its own work (linters, tests, etc.)
- List concrete commands, not vague instructions
- Enable self-correction without human intervention
- If you find yourself repeatedly doing the same steps after the agent runs, add those to AGENTS.md

### Document Real Failures

- Keep a "Gotchas Codex" section
- Update it in version control (PRs, reviewers, changelog)
- Make it specific: "Added: 2025-01-15 (PR #123)"
- Remove obsolete gotchas as root causes are fixed

### Split Complex Topics

- Reference specialized .md files from main AGENTS.md
- Examples: PLANS.md for design iteration, ARCHITECTURE.md for system overview
- Keeps main file focused and scannable
- Enables deeper dives without clutter

### Include Common Sections

- Follow the common sections pattern: project overview, repository structure, build/test commands, helpful tools (CLI + MCP), feature workflow, gotchas, and references
- This ensures consistency across projects and makes AGENTS.md files easier to navigate

## Examples

See `examples/` directory for complete examples:

- **examples/MINIMAL.md**: Bare minimum AGENTS.md (under 50 lines)
- **examples/WEB-APP.md**: Full-featured web app with verification tools and MCP server example
- **examples/LIBRARY.md**: Library with API guidelines and publishing workflow
- **examples/GOTCHAS.md**: Rich Gotchas Codex from real project
- **examples/THIS-REPO.md**: Self-referential AGENTS.md for agent-chisels repository

## Requirements

- Project with codebase (git repository recommended)
- Access to development tools (linters, test runners, build tools)
- Understanding of project workflows and common issues

## Limitations

- Cannot automatically detect all gotchas (requires human input over time)
- Best practices may need adjustment for specific domains
- Requires ongoing maintenance to keep gotchas section relevant

## See Also

- `evaluate-skills`: Evaluate skills against best practices
- `commit-message-generator`: Generate conventional commit messages
- `verify-release-readiness`: Verify release readiness for skills and plugins
