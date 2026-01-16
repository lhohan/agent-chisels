# Minimal AGENTS.md Example

A bare-bones AGENTS.md file demonstrating brevity and focus.

```markdown
# Todo CLI App

A command-line task manager built with Node.js.

## Project Overview

A command-line task manager built with Node.js.

## Repository Structure

Key directories and files:
- `src/` - Source code
- `tests/` - Test files

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
  - Tests: `npm test`
  - Linter: `npm run lint`
  - Build: `npm run build`

- **MCP servers**
  - None configured

## Feature Workflow

Step-by-step feature implementation:
1. Identify entry points and relevant files
2. Implement and update/add tests
3. Run verification commands
4. Update gotchas if new pitfalls discovered

## Gotchas

### JSON File Corruption
- Always validate JSON before writing to disk
- Use atomic writes (write temp file, then rename)
- Added: 2025-01-12 (Issue #45)
```

**Line count: ~25 lines**

## Why This Works

- Under 100 lines (well under!)
- Lists verification tools (tests, linter, build)
- Has living Gotchas section
- Clear, actionable instructions
- No unnecessary explanations
