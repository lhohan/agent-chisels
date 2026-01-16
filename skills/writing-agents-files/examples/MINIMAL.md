# Minimal AGENTS.md Example

A bare-bones AGENTS.md file demonstrating brevity and focus.

```markdown
# Todo CLI App

A command-line task manager built with Node.js.

## Development

Run tests before committing:
```bash
npm test
```

Fix linting issues:
```bash
npm run lint
```

Build the CLI:
```bash
npm run build
```

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
