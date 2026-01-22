# Original Prompt (Extracted from Conversation)

The user wants to build a CLI tool called `llm-usage` that analyzes usage statistics from AI coding assistants (OpenCode and Claude Code). The tool should be project-aware - when run in a directory, it should find and analyze usage data for that specific project. It should also walk up parent directories to find the project if needed (similar to how git finds `.git` directories).

The tool needs to track which models were used for sessions, including session counts per model, message counts per model, token usage per model, and usage over time (daily breakdown). Both OpenCode and Claude Code store this data, but in different formats and locations.

OpenCode stores data in `~/.local/share/opencode/storage/` with JSON files organized by project hash, sessions, and messages. Each message contains model information (modelID, providerID) and token counts. Claude Code stores data in `~/.claude/projects/` with JSONL files per session, each line containing message data with model and usage information.

The output should be JSON to stdout so it can be piped to other tools. The user wants separate sections for OpenCode and Claude Code statistics. A global view with `--all` flag should show stats across all projects. Date filtering should be supported with ISO date format (`--from 2026-01-01 --to 2026-01-22`).

The implementation should be a Bash script using `jq` for JSON parsing. If no project is found, the tool should error with a helpful message. The tool should handle edge cases like no data found, no jq installed, etc.

---
*Extracted by Clavix on 2026-01-22. See optimized-prompt.md for enhanced version.*
