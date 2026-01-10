# JJ Plugin

This plugin ensures Claude Code uses Jujutsu (`jj`) commands instead of git when working in Jujutsu repositories.

## Features

- **SessionStart Hook**: Lightweight reminder that the repository uses `jj`, pointing to the split skills and manual command.
- **Shared Detection Script**: `scripts/detect-jj.sh` provides a check for detecting Jujutsu repositories.
- **Split Skills**: 
  - `detecting-jujutsu`: For verifying if a repository uses JJ by running the shared detection script.
  - `using-jujutsu`: Comprehensive guide based on `jj-vcs.md`.
- **Manual Command**: `/use-jj` command for manual reinforcement and brain resets.

## Usage

### Automatic Activation

The plugin detects a Jujutsu repository at session start and injects a concise but firm reminder. This reminder explicitly instructs the assistant to use the specialized skills before acting.

### Skill Invocation

Claude is instructed to use the skills as a "pre-flight check" for VCS operations. You can also explicitly trigger them:
- Ask "Are we using jj?" or "What VCS is this?" to trigger `detecting-jujutsu`.
- Ask "How do I commit with jj?" or "Show me jj revsets" to trigger `using-jujutsu`.

### Manual Activation
Use `/use-jj` to reset the model's VCS context at any time.

## Configuration

The plugin uses a SessionStart hook defined in `hooks/hooks.json` which executes `hooks-handlers/jj-reminder.sh`.

## Token Cost

This plugin adds minimal tokens to each session in Jujutsu repositories by using a concise reminder. Detailed guidance is only loaded when skills are triggered.

## Why Hooks?

We use hooks over skills for initial detection to guarantee the context is present from the first prompt, overcoming the strong training bias towards `git`. See [decision-log.md](./decision-log.md) for more details.

## Plugin history

To understand the context of this plugin, and why things are implemented the way they are, also consult the [decision-log.md](./decision-log.md).
