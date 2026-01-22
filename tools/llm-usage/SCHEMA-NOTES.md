# OpenCode Schema Notes

## Project Structure

```
~/.local/share/opencode/storage/
├── project/                    # Project records (1 JSON per project)
│   └── {projectHash}.json
├── session/                    # Sessions organized by project
│   └── {projectHash}/
│       └── ses_{sessionId}.json
└── message/                    # Messages organized by session
    └── ses_{sessionId}/
        └── msg_{messageId}.json
```

## Field Mapping

### Project (`project/{hash}.json`)

| Field | JSON Path | Type | Notes |
|-------|-----------|------|-------|
| Project ID | `.id` | string | SHA256 hash |
| Worktree | `.worktree` | string | Absolute path to project root |
| VCS | `.vcs` | string | Usually "git" |
| Created | `.time.created` | integer | Unix timestamp (milliseconds) |
| Updated | `.time.updated` | integer | Unix timestamp (milliseconds) |

### Session (`session/{projectHash}/ses_{sessionId}.json`)

| Field | JSON Path | Type | Notes |
|-------|-----------|------|-------|
| Session ID | `.id` | string | Format: `ses_{randomId}` |
| Project ID | `.projectID` | string | Links to project hash |
| Directory | `.directory` | string | Working directory (may be nested) |
| Title | `.title` | string | Session title |
| Created | `.time.created` | integer | Unix timestamp (ms) |
| Updated | `.time.updated` | integer | Unix timestamp (ms) |

### Message (`message/ses_{sessionId}/msg_{messageId}.json`)

| Field | JSON Path | Type | Notes |
|-------|-----------|------|-------|
| Message ID | `.id` | string | Format: `msg_{randomId}` |
| Session ID | `.sessionID` | string | Links to session |
| Role | `.role` | string | "user" or "assistant" |
| Created | `.time.created` | integer | Unix timestamp (ms) |
| Model Provider | `.model.providerID` | string | e.g., "google", "opencode" |
| Model ID | `.model.modelID` | string | e.g., "antigravity-gemini-3-flash" |
| Usage | `.usage` | object | **Always null in sampled data** |

### Key Observations

1. **Token usage is not available** in OpenCode message records (`.usage` is always `null`)
2. **Model info only on user messages** - Assistant messages have `model: null`
3. **Timestamps are milliseconds** - Unix epoch in ms, not seconds
4. **Session = directory** under `session/{projectHash}/`
5. **Worktree path** is the key for project matching

## Date Filtering Strategy

For daily breakdown, use `.time.created` from messages (if available) or fall back to session `.time.created`.

---

# Claude Code Schema Notes

## Project Structure

```
~/.claude/projects/
└── -{urlEncodedPath}/          # URL-encoded absolute path
    ├── sessions-index.json     # Session metadata index
    └── {sessionId}.jsonl       # Per-session JSONL lines
```

### Path Encoding

Project paths are URL-encoded with a leading dash:
- `/Users/hans/dev/agent-chisels` → `-Users-hans-dev-agent-chisels`

## Field Mapping (JSONL per line)

| Field | JSON Path | Type | Notes |
|-------|-----------|------|-------|
| Session ID | `.sessionId` | string | UUID format |
| Role | `.message.role` | string | "user" or "assistant" |
| Model | `.message.model` | string | e.g., "claude-opus-4-5-20251101" |
| Input Tokens | `.message.usage.input_tokens` | integer | |
| Output Tokens | `.message.usage.output_tokens` | integer | |
| Cache Creation | `.message.usage.cache_creation_input_tokens` | integer | |
| Cache Read | `.message.usage.cache_read_input_tokens` | integer | |
| Timestamp | `.timestamp` | string | ISO 8601 format |
| UUID | `.uuid` | string | Message UUID |
| Parent UUID | `.parentUuid` | string | Links messages in thread |

### Key Observations

1. **One file per session** - `{sessionId}.jsonl` contains all messages
2. **Usage only on assistant messages** - User messages have no `.message.usage`
3. **Timestamps are ISO 8601** - e.g., "2026-01-20T20:31:22.965Z"
4. **Model is a string** - Not nested like OpenCode
5. **sessions-index.json** provides quick lookup but we parse JSONL for accuracy

## Date Filtering Strategy

Use `.timestamp` directly (ISO format is easily parseable).

---

# Combined Usage Summary

| Metric | OpenCode | Claude Code |
|--------|----------|-------------|
| Project ID | Hash from `.id` in `project/` | URL-encoded path in directory name |
| Session ID | `ses_{id}` from directory | UUID from `.sessionId` |
| Model ID | `.model.modelID` | `.message.model` |
| Input Tokens | **NOT AVAILABLE** | `.message.usage.input_tokens` |
| Output Tokens | **NOT AVAILABLE** | `.message.usage.output_tokens` |
| Messages | Count messages per session | Count JSONL lines per session |
| Timestamp (ms) | `.time.created` (ms) | `.timestamp` (ISO 8601) |

### Output Schema Decision

Since OpenCode doesn't have token usage, the output will be:

```json
{
  "project": "/path/to/project",
  "time_range": { "from": "...", "to": "..." },
  "opencode": {
    "found": true,
    "sessions": 5,
    "sessions_by_model": { "antigravity-gemini-3-flash": 5 },
    "messages": 42,
    "messages_by_model": { "antigravity-gemini-3-flash": 42 },
    "tokens": null  // Not available
  },
  "claude_code": {
    "found": true,
    "sessions": 12,
    "sessions_by_model": { "claude-opus-4-5-20251101": 10, "claude-sonnet-4-20251101": 2 },
    "messages": 156,
    "messages_by_model": { "claude-opus-4-5-20251101": 140, "claude-sonnet-4-20251101": 16 },
    "tokens": {
      "claude-opus-4-5-20251101": { "input": 50000, "output": 25000 },
      "claude-sonnet-4-20251101": { "input": 8000, "output": 4000 }
    }
  }
}
```

---

*Generated by Phase 1 schema reconnaissance*
