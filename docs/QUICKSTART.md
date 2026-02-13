# Quickstart

This repo is optimized for progressive disclosure: use `AGENTS.md` as the map and follow links for deeper guidance.

## Work Tracking (bd)

- This project uses `bd` (beads) for all issues/tasks. Do not use markdown TODO lists.
- Common commands:

```bash
bd ready --json
bd create "Title" --description "Details" -t task -p 2 --json
bd update <id> --status in_progress --json
bd close <id> --reason "Done" --json
```

## Skills + Verification

- Source of truth: `agentfiles/shared/skills/`
- Sync skills for local dogfooding in this repo:

```bash
bash scripts/sync-skills.sh
```

- Validate skill frontmatter and basic structure:

```bash
bash scripts/verify-skills-static.sh
```

## Release Prep

- Use `verify-release-readiness` (project-level skill in `.claude/skills/verify-release-readiness/`).
- Detect changed skills + version bumps:

```bash
bash .claude/skills/verify-release-readiness/scripts/detect-changes.sh
```

## Related Docs

- `agentfiles/README.md`
- `plugins/AGENTS.md`
- `docs/decision-log.md`
