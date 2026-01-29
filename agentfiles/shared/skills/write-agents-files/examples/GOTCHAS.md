# Gotchas Codex Example

Comprehensive example of a living Gotchas section that evolves with the project.

## What Makes a Good Gotcha Entry

Each entry should:
1. **Be specific**: Describe the exact mistake
2. **Be actionable**: Show how to avoid or fix it
3. **Include metadata**: Date added and source (PR/Issue/Incident)
4. **Stay relevant**: Remove when root cause is fixed

## Example Gotchas Section

This is a drop-in `## Gotchas Codex` section. In a full AGENTS.md, also include:
- Project overview and structure
- Build and test commands
- Helpful tools (CLI + MCP)
- Feature workflow
- References to task-specific guidance

```markdown
## Gotchas Codex

Common mistakes to avoid (continuously updated):

### API Rate Limiting
- External weather API: 100 requests/minute limit
- Implement exponential backoff: 1s, 2s, 4s, 8s delays
- Cache responses for 5 minutes minimum
- Added: 2025-01-15 (PR #234) - After production 429 errors

### Database Migrations
- Never use auto-generated sequential IDs for migration names
- Format: `YYYY-MM-DD-HH-MM-descriptive-name.sql`
- Always test rollback before deploying to production
- Run migrations in transaction when possible
- Added: 2025-01-10 (Incident #189) - Failed rollback caused downtime

### Date Handling
- All timestamps must be stored in UTC in database
- Convert to user timezone only for display
- Never use `new Date()` in tests - use `jest.useFakeTimers()`
- Added: 2025-01-08 (PR #210) - Flaky test suite from time dependencies

### React State Updates
- Product filtering in ProductList is expensive (10k+ items)
- Use `useMemo` with proper dependencies
- Debounce search input (300ms)
- Added: 2025-01-05 (Performance audit) - Page load reduced from 3s to 0.5s

### Environment Variables
- `.env` files are git-ignored but `.env.example` is committed
- Never commit actual API keys (use placeholder in .env.example)
- Validate required env vars at app startup
- Added: 2025-01-03 (Security audit)

### Git Commit Messages
- Use conventional commits: `feat:`, `fix:`, `docs:`, etc.
- Reference issue numbers: `fix: resolve login timeout (#145)`
- Keep first line under 72 characters
- Added: 2024-12-28 (Team decision) - Enables automated changelog

### Removed Gotchas

~~SQL Injection in Search~~ - Fixed in PR #156 by switching to parameterized queries everywhere

~~Missing CORS Headers~~ - Fixed in PR #178 by adding proper middleware configuration
```

## Maintenance Protocol

**When to add a gotcha:**
- Production incident occurs
- PR reviewer catches repeated mistake
- New developer makes predictable error
- Performance issue discovered

**When to remove a gotcha:**
- Root cause is permanently fixed (e.g., linter rule added)
- Architecture change makes it impossible
- No longer relevant to current codebase

**Keep strikethrough removed gotchas** for 2-3 months so team can see evolution, then archive to separate `GOTCHAS-ARCHIVE.md` file.

## Benefits

1. **Prevents repeated mistakes**: Agent knows common pitfalls
2. **Documents institutional knowledge**: New team members learn quickly
3. **Shows evolution**: Team can see improvements over time
4. **Actionable**: Each entry has concrete fix
5. **Living document**: Grows with the project
