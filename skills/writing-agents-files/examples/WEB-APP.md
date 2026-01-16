# Web App AGENTS.md Example

Full-featured AGENTS.md for a web application with comprehensive verification tools.

```markdown
# E-Commerce Dashboard

Admin dashboard for managing products, orders, and customers.

## Project Overview

Admin dashboard for managing products, orders, and customers.

## Repository Structure

Key directories and files:
- `frontend/` - React + TypeScript frontend
- `backend/` - Node.js + Express backend
- `tests/` - Unit and integration tests
- `e2e/` - End-to-end tests
- `config/` - Configuration files

## Development Workflow

1. Create feature branch from `main`
2. Implement changes with tests
3. Run verification tools (see below)
4. Open PR with test results

## Feature Workflow

Step-by-step feature implementation:
1. Identify entry points and relevant files
2. Make a small plan (if non-trivial)
3. Implement and update/add tests
4. Run verification commands
5. Update gotchas/docs if new pitfalls discovered
6. Summarize changes and remaining risks

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
  - Type check: `npm run typecheck` - Catch TypeScript errors
  - Linter: `npm run lint` - Enforce code style
  - Tests: `npm test` - Run full test suite
  - Build: `npm run build` - Verify production build
  - E2E: `npm run test:e2e` - Test critical user flows

- **MCP servers**
  - **Context7**: Use for framework/library API lookups and canonical usage examples (prefer over guessing).
    - When: Introducing new dependencies, using unfamiliar APIs, resolving subtle option/config questions.

All checks must pass before committing.

## Gotchas Codex

### Database Connection Pooling
- Max pool size is 20 connections
- Always release connections in finally blocks
- Added: 2025-01-10 (Incident #203)

### React Re-renders
- Use `useMemo` for expensive product list filtering
- Product page renders are tracked in monitoring
- Added: 2025-01-08 (PR #156)

### API Authentication
- Auth tokens expire after 1 hour
- Always handle 401 responses with refresh logic
- Added: 2025-01-05 (PR #142)

## Detailed Guidelines

For specific areas, see:

- **API Design**: [API.md](./API.md) - RESTful conventions
- **Testing**: [TESTING.md](./TESTING.md) - Test strategies
- **Deployment**: [DEPLOYMENT.md](./DEPLOYMENT.md) - Release process
```

**Line count: ~60 lines**

## Why This Works

- Under 100 lines
- Comprehensive verification tools section (unlocks agentic loops)
- Rich Gotchas Codex with dates and sources
- Points to specialized files for details
- Clear workflow without over-explaining
