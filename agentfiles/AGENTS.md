# Agentfiles Guidelines

## Project Structure & Module Organization
This directory contains shared agent artifacts and per-agent Stow packages.

- `shared/` is the source of truth:
  - `shared/skills/` (skills as `SKILL.md`)
  - `shared/commands/`, `shared/agents/`, `shared/prompts/`
- `claude-code/`, `opencode/`, `mistral-vibe/` are GNU Stow packages that expose
  symlinked content into tool-specific config roots (for example, `~/.claude/`).
- `mise.toml` defines reusable tasks for Stow deployment.

## Build, Test, and Development Commands
There is no build step. Use Stow tasks to deploy or validate changes.

- `mise run stow:check` — verify Stow is installed.
- `mise run stow:dry-run:all` — preview all symlink changes without writing.
- `mise run stow:all` / `mise run unstow:all` — deploy or remove all agents.
- Direct Stow example: `stow -v --no-folding -t ~ claude-code`.

## Coding Style & Naming Conventions
- Keep Markdown formatting consistent with neighboring files (headings, lists,
  and short, scannable paragraphs).

## Testing Guidelines
No automated test suite exists for `agentfiles/`. Verify changes by:

- Running `mise run stow:dry-run:*` before deployment.
- Spot-checking symlinks after deployment (example: `ls -la ~/.claude/skills`).
- Ensuring SKILL.md frontmatter remains valid and updated for any edits.

## Commit & Pull Request Guidelines
Commit messages follow a Conventional Commits style:
`type(scope): summary` (examples: `feat(agentfiles): ...`, `docs: ...`).

## Deployment & Safety Notes
Stow uses `--no-folding`, creating individual file symlinks into `~`. Prefer a
`stow:dry-run:*` first to avoid accidental overwrites or conflicts.
