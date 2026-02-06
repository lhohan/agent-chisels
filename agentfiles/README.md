# agentfiles

Shared artifacts and per-agent Stow packages for deploying skills, commands, agents, and prompts to multiple AI coding assistants.

## Structure

```
agentfiles/
├── shared/                      # Source of truth for all artifacts
│   ├── skills/
│   ├── commands/
│   ├── agents/
│   └── prompts/
├── codex/                       # Stow package → ~/.codex/
│   ├── .codex/skills/chisel-skills → ../../../shared/skills
│   ├── .agents/skills/chisel-skills → ../../../shared/skills
│   └── .codex/agents → ../../shared/agents
├── claude-code/                 # Stow package → ~/.claude/
│   └── .claude/{skills,commands,agents} → ../../shared/*
├── opencode/                    # Stow package → ~/.config/opencode/
│   └── .config/opencode/{skills,commands,agents} → ../../../shared/*
├── mistral-vibe/                # Stow package → ~/.vibe/
│   └── .vibe/{prompts,agents} → ../../shared/*
└── mise.toml                    # Stow tasks
```

Each agent directory is a GNU Stow package. The inner directories contain symlinks pointing back to `shared/`, so deploying with Stow creates a two-level symlink chain: `~ → repo/agentfiles/<agent>/... → shared/...`.

## Usage

Deploy agent configs to your home directory:

```bash
cd agentfiles
mise run stow:all          # deploy all agents
mise run stow:codex        # deploy just codex
mise run stow:claude-code  # deploy just claude-code
mise run unstow:all        # remove all agent symlinks from ~
```

Stow is configured with `--no-folding` to create individual file symlinks rather than folding entire directories.

## Codex UI Picker Note

Codex ignores symlinked `SKILL.md` files, but it does follow symlinked
directories under a skills root. This repo installs symlinked subdirectories at
`~/.codex/skills/chisel-skills` and `~/.agents/skills/chisel-skills` so Codex can
discover shared skills without symlinking `~/.codex/skills` itself.
