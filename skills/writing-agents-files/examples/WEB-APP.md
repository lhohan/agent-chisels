# Web App AGENTS.md Example

Full-featured AGENTS.md for a web application with comprehensive verification tools.

```markdown
# E-Commerce Dashboard

Admin dashboard for managing products, orders, and customers.

## Tech Stack

- Frontend: React + TypeScript + Tailwind
- Backend: Node.js + Express + PostgreSQL
- Testing: Jest + React Testing Library

## Development Workflow

1. Create feature branch from `main`
2. Implement changes with tests
3. Run verification tools (see below)
4. Open PR with test results

## Verification Tools

After making changes, verify using:

1. **Type check**: `npm run typecheck` - Catch TypeScript errors
2. **Linter**: `npm run lint` - Enforce code style
3. **Tests**: `npm test` - Run full test suite
4. **Build**: `npm run build` - Verify production build
5. **E2E**: `npm run test:e2e` - Test critical user flows

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
