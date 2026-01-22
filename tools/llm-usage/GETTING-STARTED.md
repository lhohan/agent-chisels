# Getting Started with llm-usage

This guide will help you get up and running with `llm-usage` in 5 minutes.

## Prerequisites

### Required

- **Bash** 4.0 or later (check with `bash --version`)
- **jq** 1.6 or later (JSON processor)

### Optional

- **Rust** 1.70+ (for running tests)
- **Nix** (for reproducible development environment)

## Installation

### Quick Install

```bash
# Clone the repository
cd ~/dev
git clone https://github.com/yourusername/agent-chisels
cd agent-chisels/tools/llm-usage

# Make executable
chmod +x llm-usage

# Add to PATH (choose one method)
# Method 1: Symlink to local bin
ln -s $(pwd)/llm-usage ~/.local/bin/llm-usage

# Method 2: Add to PATH in shell config
echo 'export PATH="$HOME/dev/agent-chisels/tools/llm-usage:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Install jq

If you don't have `jq` installed:

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Fedora/RHEL
sudo dnf install jq

# Arch Linux
sudo pacman -S jq
```

Verify installation:
```bash
jq --version
# Should output: jq-1.6 or later
```

## First Run

### Check Your Usage

Run from any project directory:

```bash
llm-usage
```

You should see JSON output like:

```json
{
  "generated_at": "2026-01-22T16:30:00Z",
  "project": "/Users/hans/dev/my-project",
  "time_range": {
    "from": "",
    "to": ""
  },
  "opencode": {
    "found": true,
    "sessions": 42,
    "messages": 156,
    ...
  },
  "claude_code": {
    "found": true,
    "sessions": 23,
    "messages": 89,
    ...
  }
}
```

### Pretty Print with jq

```bash
# Show just the summary
llm-usage | jq '{
  project,
  opencode: .opencode | {sessions, messages},
  claude_code: .claude_code | {sessions, messages}
}'

# Output:
# {
#   "project": "/Users/hans/dev/my-project",
#   "opencode": {
#     "sessions": 42,
#     "messages": 156
#   },
#   "claude_code": {
#     "sessions": 23,
#     "messages": 89
#   }
# }
```

## Common Usage Patterns

### 1. Check Current Project

```bash
# From project directory
cd ~/dev/my-project
llm-usage
```

The tool will:
1. Check current directory for LLM data
2. Walk up parent directories if not found
3. Report data for the first project found

### 2. Check All Projects

```bash
# Aggregate across all projects
llm-usage --all
```

This gives you a total across all projects in:
- `~/.local/share/opencode/storage/`
- `~/.claude/projects/`

### 3. Check Specific Project

```bash
# Specify project path explicitly
llm-usage --project ~/dev/my-project
```

Useful when:
- Running from outside the project
- Scripting/automation
- Checking multiple projects

### 4. Filter by Date Range

```bash
# This month only
llm-usage --from 2026-01-01 --to 2026-01-31

# Last week
llm-usage --from 2026-01-15 --to 2026-01-22

# Combine with --all
llm-usage --all --from 2026-01-01
```

## Understanding the Output

### Top-Level Fields

```json
{
  "generated_at": "2026-01-22T16:30:00Z",  // When report was generated
  "project": "/path/to/project",            // Project path (empty for --all)
  "time_range": {
    "from": "2026-01-01",                   // Filter start (empty if none)
    "to": "2026-01-31"                      // Filter end (empty if none)
  },
  "opencode": { ... },                      // OpenCode stats
  "claude_code": { ... }                    // Claude Code stats
}
```

### OpenCode/Claude Code Stats

```json
{
  "found": true,                            // Data found for this tool
  "sessions": 42,                           // Total sessions
  "sessions_by_model": {                    // Sessions per model
    "gpt-4": 30,
    "claude-opus": 12
  },
  "messages": 156,                          // Total messages
  "messages_by_model": {                    // Messages per model
    "gpt-4": 120,
    "claude-opus": 36
  },
  "tokens": {                               // Token usage per model
    "gpt-4": {
      "input": 50000,
      "output": 25000
    }
  },
  "usage_by_date": {                        // Daily breakdown
    "2026-01-20": {
      "sessions": 5,
      "messages": 23
    }
  }
}
```

## Practical Examples

### Example 1: Monthly Report

```bash
#!/bin/bash
# monthly-report.sh - Generate monthly LLM usage report

MONTH="2026-01"
OUTPUT="llm-usage-${MONTH}.json"

llm-usage --all \
  --from "${MONTH}-01" \
  --to "${MONTH}-31" \
  > "$OUTPUT"

echo "Report saved to $OUTPUT"

# Show summary
jq '{
  total_sessions: (.opencode.sessions + .claude_code.sessions),
  total_messages: (.opencode.messages + .claude_code.messages),
  opencode_tokens: .opencode.tokens,
  claude_tokens: .claude_code.tokens
}' "$OUTPUT"
```

### Example 2: Compare Projects

```bash
#!/bin/bash
# compare-projects.sh - Compare usage across projects

for project in ~/dev/*/; do
  echo "=== $(basename "$project") ==="
  llm-usage --project "$project" | jq '{
    opencode: .opencode.messages,
    claude: .claude_code.messages
  }'
  echo
done
```

### Example 3: Daily Usage Trend

```bash
#!/bin/bash
# daily-trend.sh - Show daily message counts

llm-usage --all | jq -r '
  .opencode.usage_by_date | to_entries[] |
  "\(.key): \(.value.messages) messages"
' | sort
```

Output:
```
2026-01-15: 45 messages
2026-01-16: 67 messages
2026-01-17: 23 messages
...
```

### Example 4: Token Cost Estimation

```bash
#!/bin/bash
# estimate-cost.sh - Estimate API costs

# Pricing (example rates per 1M tokens)
GPT4_INPUT=30    # $30/1M input tokens
GPT4_OUTPUT=60   # $60/1M output tokens

llm-usage --all | jq --arg in_rate "$GPT4_INPUT" --arg out_rate "$GPT4_OUTPUT" '
  .opencode.tokens["gpt-4"] as $tokens |
  if $tokens then
    {
      input_tokens: $tokens.input,
      output_tokens: $tokens.output,
      input_cost: (($tokens.input / 1000000) * ($in_rate | tonumber)),
      output_cost: (($tokens.output / 1000000) * ($out_rate | tonumber)),
      total_cost: ((($tokens.input / 1000000) * ($in_rate | tonumber)) +
                   (($tokens.output / 1000000) * ($out_rate | tonumber)))
    }
  else
    "No GPT-4 usage found"
  end
'
```

## Troubleshooting

### "No LLM usage data found"

**Problem**: Tool can't find any data for current directory

**Solutions**:

1. Check if you're in a project directory:
   ```bash
   pwd
   # Should be in a directory that has been used with OpenCode/Claude Code
   ```

2. Try `--all` to see all projects:
   ```bash
   llm-usage --all
   ```

3. Check data directories exist:
   ```bash
   ls ~/.local/share/opencode/storage/project/
   ls ~/.claude/projects/
   ```

4. Specify project explicitly:
   ```bash
   llm-usage --project ~/dev/my-project
   ```

### "jq: command not found"

**Problem**: `jq` is not installed

**Solution**: Install jq (see [Installation](#install-jq) section above)

### Empty Output / No Data

**Problem**: Tool runs but shows `found: false` for both sources

**Possible causes**:

1. **Never used OpenCode/Claude Code in this project**
   - Solution: Use the tools first, then run `llm-usage`

2. **Data in different location**
   - Check: `echo $HOME/.local/share/opencode/storage`
   - Check: `echo $HOME/.claude/projects`

3. **Permissions issue**
   - Check: `ls -la ~/.local/share/opencode/storage/`
   - Fix: `chmod -R u+r ~/.local/share/opencode/storage/`

### Slow Performance

**Problem**: Tool takes a long time to run

**Causes**:
- Large number of projects (with `--all`)
- Large number of messages (10,000+)

**Solutions**:

1. Use project-specific queries:
   ```bash
   llm-usage --project ~/dev/my-project
   ```

2. Use date filters:
   ```bash
   llm-usage --from 2026-01-01
   ```

3. Check data size:
   ```bash
   find ~/.local/share/opencode/storage/message -name "*.json" | wc -l
   ```

## Development Setup

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

### Debug Mode

Enable debug output to see what the tool is doing:

```bash
LLM_USAGE_DEBUG=1 llm-usage
```

This shows:
- Path comparisons during project discovery
- Which directories are being checked
- Why projects are/aren't matching

## Next Steps

### Learn More

- Read [ARCHITECTURE.md](./ARCHITECTURE.md) for technical details
- Read [SCHEMA-NOTES.md](./SCHEMA-NOTES.md) for data format details
- Check [sonnet-fix.md](./sonnet-fix.md) for recent bug fixes

### Customize

Create shell functions for common tasks:

```bash
# Add to ~/.bashrc or ~/.zshrc

# Quick usage summary
alias llm-summary='llm-usage | jq "{
  sessions: (.opencode.sessions + .claude_code.sessions),
  messages: (.opencode.messages + .claude_code.messages)
}"'

# This month's usage
alias llm-month='llm-usage --from $(date +%Y-%m-01)'

# Project usage
llm-project() {
  llm-usage --project "$1" | jq '{
    project,
    total_messages: (.opencode.messages + .claude_code.messages)
  }'
}
```

### Integrate

Use in scripts and automation:

```bash
# CI/CD: Track LLM usage in builds
if [ -f .llm-usage-budget ]; then
  BUDGET=$(cat .llm-usage-budget)
  ACTUAL=$(llm-usage | jq '.opencode.messages + .claude_code.messages')
  if [ "$ACTUAL" -gt "$BUDGET" ]; then
    echo "Warning: LLM usage ($ACTUAL) exceeds budget ($BUDGET)"
  fi
fi
```

## Getting Help

### Common Issues

1. **Path issues on macOS**: The tool handles `/var` vs `/private/var` automatically
2. **Large file counts**: The tool uses `find` to handle 10,000+ files
3. **Multiple sessions**: Token aggregation works correctly across sessions

### Report Bugs

If you encounter issues:

1. Run with debug mode: `LLM_USAGE_DEBUG=1 llm-usage`
2. Check test suite: `cd cli-tests && cargo test`
3. Review [sonnet-fix.md](./sonnet-fix.md) for known issues
4. Open an issue with:
   - Command you ran
   - Expected vs actual output
   - Debug output
   - OS and version

## Quick Reference

```bash
# Basic usage
llm-usage                              # Current project
llm-usage --all                        # All projects
llm-usage --project /path              # Specific project

# Date filtering
llm-usage --from 2026-01-01            # From date
llm-usage --to 2026-01-31              # To date
llm-usage --from 2026-01-01 --to 2026-01-31  # Range

# Output formatting
llm-usage | jq .                       # Pretty print
llm-usage | jq '.opencode'             # OpenCode only
llm-usage | jq '.claude_code.tokens'   # Claude tokens

# Debugging
LLM_USAGE_DEBUG=1 llm-usage            # Debug mode
llm-usage 2>&1 | tee debug.log         # Save debug output

# Testing
cd cli-tests && cargo test             # Run tests
cargo test test_name -- --nocapture    # Run specific test
```

## Success!

You're now ready to track your LLM usage! Start with:

```bash
llm-usage | jq '{
  project,
  total_sessions: (.opencode.sessions + .claude_code.sessions),
  total_messages: (.opencode.messages + .claude_code.messages)
}'
```

Happy tracking! 🚀
