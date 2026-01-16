# Library AGENTS.md Example

AGENTS.md for an open-source library with API guidelines and publishing workflow.

```markdown
# DateUtils Library

Zero-dependency TypeScript library for date manipulation and formatting.

## Development

Run verification tools before committing:

1. **Type check**: `npm run typecheck` - Ensure type safety
2. **Linter**: `npm run lint` - Check code style
3. **Tests**: `npm test` - Run unit tests (aim for 100% coverage)
4. **Build**: `npm run build` - Verify ES and CJS builds
5. **Docs**: `npm run docs` - Generate API documentation

## API Design Principles

- All functions must be pure (no side effects)
- Accept Date objects or ISO strings as input
- Return Date objects or primitives (never mutate inputs)
- For details, see [API.md](./API.md)

## Gotchas Codex

### Timezone Edge Cases
- Date parsing assumes UTC unless timezone specified
- Use `parseISO` from our utils, not `new Date(string)`
- Test timezone-dependent code with TZ env var
- Added: 2025-01-12 (Issue #67)

### Breaking Changes
- Any signature change is breaking (we follow semver strictly)
- Deprecate first, remove in next major version
- Document breaking changes in CHANGELOG.md
- Added: 2025-01-08 (Team decision)

### Bundle Size
- Each new function adds to bundle size
- Tree-shaking must work (test with rollup-plugin-visualizer)
- Avoid heavy dependencies (we're zero-dependency)
- Added: 2025-01-05 (PR #89)

## Publishing

See [PUBLISHING.md](./PUBLISHING.md) for release workflow.
```

**Line count: ~50 lines**

## Why This Works

- Under 100 lines
- Library-specific verification tools (type check, build, docs)
- API design principles without over-explaining
- Gotchas tailored to library concerns (semver, bundle size, timezone)
- Points to specialized files (API.md, PUBLISHING.md)
- Emphasis on purity and testing
