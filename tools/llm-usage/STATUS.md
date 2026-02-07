# llm-usage - Current Status

## Summary

`llm-usage` is a bash-based CLI that reports local LLM usage statistics from
OpenCode and Claude Code. It aggregates sessions, messages, model counts, token
usage (where available), and daily breakdowns into a single JSON report. The
tool favors portability and minimal dependencies (bash + jq) over a compiled
runtime.

## What Works Today

- CLI flags: `--all`, `--project`, `--from`, `--to`.
- Project discovery by walking up directories and matching OpenCode/Claude Code
  project metadata.
- OpenCode aggregation from `~/.local/share/opencode/storage/`.
- Claude Code aggregation from `~/.claude/projects/` (JSONL parsing).
- JSON output schema with combined results and metadata.
- Test harness: Rust-based DSL with end-to-end integration tests.

## Data Sources

- OpenCode:
  - Project records: `storage/project/{project_id}.json`
  - Sessions: `storage/session/{project_id}/ses_*.json`
  - Messages: `storage/message/{session_id}/msg_*.json`
- Claude Code:
  - Projects: `~/.claude/projects/-{url-encoded-path}/`
  - Sessions: `{session_id}.jsonl`

## Known Constraints

- OpenCode token usage is typically unavailable (usage fields are null).
- JSON parsing errors (invalid/corrupt files) are not fully surfaced.
- Performance is linear in message count; `--all` can be slow on large data.

## Implementation Notes

- Script: `llm-usage` (bash + jq).
- Project discovery handles macOS path canonicalization (`/var` vs `/private/var`).
- Aggregation uses `find` to avoid shell glob ARG_MAX limits.
- Output schema includes: `sessions`, `messages`, `sessions_by_model`,
  `messages_by_model`, `tokens`, and `usage_by_date` per source.

## Testing

- Location: `cli-tests/`
- Uses a typed-phase DSL (Given/When/Then) for integration tests.
- Coverage includes: project discovery, date filtering, aggregation, error
  handling, and `--all` mode.

## Near-Term Improvements (Documented)

- Better error handling for jq/JSON errors.
- Progress indicators for `--all`.
- Caching or database backend for faster repeated queries.
- Optional parallel processing for project scans.

## How to Run

```bash
llm-usage
llm-usage --project /path/to/project
llm-usage --all
llm-usage --from 2026-01-01 --to 2026-01-31
```
