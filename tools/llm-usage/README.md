# llm-usage

Report LLM usage statistics from OpenCode and Claude Code.

## Installation

```bash
# Clone and add to PATH
git clone https://github.com/yourusername/llm-usage
export PATH="$PWD/llm-usage:$PATH"
```

Or simply copy `llm-usage` to a directory in your PATH.

## Usage

```bash
# Report for current project
llm-usage

# Report for specific project
llm-usage --project /path/to/project

# Report for all projects
llm-usage --all

# Filter by date range
llm-usage --from 2026-01-01 --to 2026-01-31
```

## Output Format

```json
{
  "generated_at": "2026-01-22T12:57:48Z",
  "project": "/Users/hans/dev/my-project",
  "time_range": {
    "from": "",
    "to": ""
  },
  "opencode": {
    "found": true,
    "sessions": 74,
    "sessions_by_model": {},
    "messages": 1344,
    "messages_by_model": {...},
    "tokens": {...},
    "usage_by_date": {...}
  },
  "claude_code": {
    "found": true,
    "sessions": 97,
    "sessions_by_model": {...},
    "messages": 111,
    "messages_by_model": {...},
    "tokens": {...},
    "usage_by_date": {...}
  }
}
```

## Testing

This project includes a Rust-based test harness using the Universal DSL pattern.

### Running Tests

```bash
cd tools/llm-usage/cli-tests
cargo test
```

### Using Nix

```bash
cd tools/llm-usage
nix develop
cargo test
```

## Environment Variables

For testing, you can override the default data directories:

```bash
LLM_USAGE_OPENCODE_STORAGE=/path/to/opencode/storage \
LLM_USAGE_CLAUDE_PROJECTS=/path/to/claude/projects \
    llm-usage
```

## Architecture

- **CLI**: Pure bash with jq for JSON processing
- **Data Sources**:
  - OpenCode: `~/.local/share/opencode/storage/`
  - Claude Code: `~/.claude/projects/`
- **Test Harness**: Rust with `assert_cmd`, `assert_fs`, `predicates`

## Future Enhancements

- Add `just test` recipe for easier testing
- Support for additional LLM providers
- Export to CSV/other formats
