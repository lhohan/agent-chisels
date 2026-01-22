# Optimized Prompt (Clavix Enhanced)

Build `llm-usage`: a Bash CLI tool that analyzes AI coding assistant usage statistics from OpenCode and Claude Code, outputting JSON data for the current project directory (or all projects with `--all` flag).

**Core behavior:**
1. Run in a directory → find matching project in OpenCode and Claude Code data stores
2. Walk up parent directories until a project match is found (like git finding `.git`)
3. Output JSON to stdout with separate sections for each tool

**CLI interface:**
```bash
llm-usage                    # Current project (default)
llm-usage --project PATH     # Specific project path
llm-usage --all              # All projects globally
llm-usage --from YYYY-MM-DD  # Filter by start date
llm-usage --to YYYY-MM-DD    # Filter by end date
```

**Data sources:**
- **OpenCode**: `~/.local/share/opencode/storage/`
  - Projects: `project/*.json` (has `worktree` field with directory path)
  - Sessions: `session/<project-hash>/ses_*.json`
  - Messages: `message/ses_*/msg_*.json` (has `modelID`, `providerID`, `tokens`)
- **Claude Code**: `~/.claude/projects/`
  - Path encoding: `/Users/hans/dev/apps` → `-Users-hans-dev-apps`
  - Sessions: `<encoded-path>/*.jsonl` (each line has `message.model`, `message.usage`)

**JSON output structure:**
```json
{
  "generated_at": "ISO8601",
  "project": "/path/to/project",
  "time_range": { "from": "YYYY-MM-DD|null", "to": "YYYY-MM-DD|null" },
  "opencode": {
    "found": true,
    "sessions": 45,
    "sessions_by_model": { "claude-opus-4-5": 30 },
    "messages_by_model": { "claude-opus-4-5": 890 },
    "tokens": { "claude-opus-4-5": { "input": 12345, "output": 6789 } },
    "usage_by_date": { "2026-01-20": { "sessions": 5, "messages": 120 } }
  },
  "claude_code": { /* same structure */ }
}
```

**Error handling:**
- If `jq` not installed: exit with error message suggesting installation
- If no project found (and not `--all`): exit with helpful error listing nearby projects that do have data
- If project found but no sessions: return valid JSON with zero counts

**Dependencies:** `jq` for JSON parsing (required)

---

## Optimization Improvements Applied

1. **[STRUCTURE]** - Reorganized from conversational flow to structured specification with clear sections: Core behavior, CLI interface, Data sources, JSON output, Error handling
2. **[CLARIFIED]** - Made vague terms specific: "analyze usage" → "count sessions, messages, and tokens per model with daily breakdown"
3. **[CLARIFIED]** - Specified exact data locations and file formats for both OpenCode and Claude Code
4. **[COMPLETENESS]** - Added JSON output structure example so implementation knows exact format
5. **[COMPLETENESS]** - Added error handling requirements that were discussed but not explicitly stated
6. **[ACTIONABILITY]** - Converted "walk up directories like git" into specific lookup logic with path encoding example
7. **[CLARITY]** - Consolidated all CLI flags into a single interface section

---
*Optimized by Clavix on 2026-01-22. This version is ready for implementation.*
