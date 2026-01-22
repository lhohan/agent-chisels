# Development Guide for llm-usage

This guide covers development practices, testing approach, and contribution guidelines for the `llm-usage` project.

## Table of Contents

- [Development Setup](#development-setup)
- [Testing Approach](#testing-approach)
- [BDD-Style DSL](#bdd-style-dsl)
- [Writing Tests](#writing-tests)
- [Debugging](#debugging)
- [Code Style](#code-style)
- [Contributing](#contributing)

## Development Setup

### Prerequisites

- **Bash** 4.0+
- **jq** 1.6+
- **Rust** 1.70+ (for tests)
- **cargo** (Rust package manager)
- **Git**

### Quick Start

```bash
# Clone repository
git clone https://github.com/yourusername/agent-chisels
cd agent-chisels/tools/llm-usage

# Install dependencies
brew install jq  # macOS
# or
sudo apt install jq  # Linux

# Run tests
cd cli-tests
cargo test
```

### Using Nix (Recommended)

```bash
cd tools/llm-usage
nix develop  # Enters shell with all dependencies
cargo test
```

The `flake.nix` provides:
- Rust toolchain
- jq
- All development dependencies
- Reproducible environment

## Testing Approach

### Philosophy

The `llm-usage` project uses a **BDD-style (Behavior-Driven Development)** testing approach with a custom DSL (Domain-Specific Language) built in Rust.

**Key Principles**:

1. **Tests as Specifications**: Tests document expected behavior
2. **Readable Tests**: Tests read like natural language
3. **Type Safety**: Compile-time guarantees for test correctness
4. **Isolation**: Each test runs in isolated temporary environment
5. **Fast Feedback**: Tests run in parallel, complete in seconds

### Test Architecture

```
cli-tests/
├── src/
│   ├── lib.rs              # Public API exports
│   ├── dsl/
│   │   └── mod.rs          # Typed-phase DSL implementation
│   └── assertions.rs       # Domain-specific assertions
├── tests/
│   ├── all_mode.rs         # --all flag tests
│   ├── date_filters.rs     # Date filtering tests
│   ├── errors.rs           # Error handling tests
│   ├── project_discovery.rs # Project detection tests
│   ├── project_flag.rs     # --project flag tests
│   ├── sessions_by_model.rs # Session aggregation tests
│   ├── tokens.rs           # Token counting tests
│   └── usage_by_date.rs    # Daily breakdown tests
└── Cargo.toml              # Dependencies
```

### Test Layers

```
┌─────────────────────────────────────────────┐
│         Test Files (tests/*.rs)             │
│  (High-level behavior specifications)       │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│      Domain Assertions (assertions.rs)      │
│  (OpenCode/Claude-specific assertions)      │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│         Typed-Phase DSL (dsl/mod.rs)        │
│  (Given-When-Then fluent API)               │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│      Fixture Builders (dsl/mod.rs)          │
│  (Generate realistic test data)             │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│         llm-usage Script (bash)             │
│  (System under test)                        │
└─────────────────────────────────────────────┘
```

## BDD-Style DSL

### Typed-Phase Pattern

The DSL uses a **typed-phase pattern** where each phase returns a different type, preventing invalid test construction at compile time.

**Phases**:

1. **Given** (`CmdGiven`) - Setup fixtures and environment
2. **When** (`CmdThen`) - Execute command
3. **Then** (`CmdThen`) - Assert results

**Type Safety**:

```rust
// ✅ Valid: phases in correct order
Cmd::given()
    .with_project_dir("/path")
    .when_run()
    .should_succeed();

// ❌ Invalid: can't call when_run() twice (compile error)
let cmd = Cmd::given().when_run();
cmd.when_run();  // Error: CmdThen doesn't have when_run()

// ❌ Invalid: can't assert before running (compile error)
Cmd::given()
    .should_succeed();  // Error: CmdGiven doesn't have should_succeed()
```

### DSL API Reference

#### Given Phase (Setup)

```rust
Cmd::given()
    // Set working directory
    .with_project_dir("/repo/my-proj")
    
    // Add OpenCode fixtures
    .with_opencode_session(
        "/repo/my-proj",           // Project path
        "ses_1",                   // Session ID
        vec![OpencodeMessage::new(
            "assistant",           // Role
            "opencode",            // Provider
            "gpt-4",               // Model
            10,                    // Input tokens
            5,                     // Output tokens
            1700000000000,         // Timestamp (ms)
        )]
    )
    
    // Add Claude Code fixtures
    .with_claude_session(
        "/repo/my-proj",           // Project path
        "session-1",               // Session ID
        vec![ClaudeMessage::new(
            "assistant",           // Role
            "claude-opus-4",       // Model
            12,                    // Input tokens
            6,                     // Output tokens
            "2026-01-20T10:00:00.000Z",  // ISO timestamp
        )]
    )
    
    // Add CLI arguments
    .with_arg("--all")
    .with_arg("--from")
    .with_arg("2026-01-01")
    
    // Or use project-specific arg
    .with_project_arg("/path/to/project")
    
    // Set environment variables
    .with_env("LLM_USAGE_DEBUG", "1")
```

#### When Phase (Execution)

```rust
    .when_run()  // Executes the command
```

This:
- Creates temporary directory structure
- Generates fixture files (JSON/JSONL)
- Sets environment variables
- Runs `llm-usage` script
- Captures stdout/stderr/exit code

#### Then Phase (Assertions)

```rust
    // Assert exit code
    .should_succeed()     // Exit code 0
    .should_fail()        // Exit code != 0
    
    // Assert stderr
    .expect_error_contains("jq")
    
    // Parse and assert JSON
    .expect_stdout_json()
        .field_eq("/project", Value::String("...".to_string()))
        .field_contains("/project", "my-proj")
        .validate()
    
    // Domain-specific assertions
    .expect_stdout_json()
        .expect_opencode(|o| {
            o.sessions(2)
             .messages(10)
             .sessions_by_model("gpt-4", 2)
             .messages_by_model("gpt-4", 10)
             .tokens("gpt-4", 100, 50)
        })
        .expect_claude_code(|c| {
            c.sessions(1)
             .messages(5)
             .tokens("claude-opus-4", 50, 25)
        })
```

### Fixture Generation

The DSL automatically generates realistic fixture data:

**OpenCode Structure**:
```
temp_dir/
└── opencode/
    └── storage/
        ├── project/
        │   └── {hash}.json          # Project metadata
        ├── session/
        │   └── {project_id}/
        │       └── ses_*.json       # Session files
        └── message/
            └── {session_id}/
                └── msg_*.json       # Message files with tokens
```

**Claude Code Structure**:
```
temp_dir/
└── claude/
    └── projects/
        └── -{encoded-path}/
            ├── sessions-index.json  # Optional index
            └── {session-id}.jsonl   # JSONL with messages
```

**Path Mapping**:
- Test path: `/repo/my-proj`
- Mapped to: `/tmp/.../workspace/repo/my-proj`
- Script sees: Mapped path
- Fixtures use: Mapped path

## Writing Tests

### Test Structure

```rust
use llm_usage_tests::{ClaudeMessage, Cmd, DomainAssertions, OpencodeMessage};
use serde_json::json;

#[test]
fn descriptive_test_name() {
    Cmd::given()
        // Setup: Create fixtures
        .with_project_dir("/repo/my-proj")
        .with_opencode_session(...)
        .with_claude_session(...)
        
        // Execute: Run command
        .when_run()
        
        // Assert: Verify behavior
        .should_succeed()
        .expect_stdout_json()
        .expect_opencode(|o| o.sessions(2).messages(10));
}
```

### Example: Testing Project Discovery

```rust
/// Test: default mode finds project by walking up directories.
#[test]
fn default_mode_discovers_project() {
    // Create a nested directory structure
    let nested_dir = Path::new("/repo/my-proj/src/components");

    Cmd::given()
        // Run from nested directory
        .with_project_dir(nested_dir)
        
        // But fixtures are at project root
        .with_opencode_session(
            "/repo/my-proj",  // Project root
            "ses_1",
            vec![OpencodeMessage::new(
                "assistant",
                "opencode",
                "gpt-4",
                10,
                5,
                1700000000000,
            )],
        )
        .with_claude_session(
            "/repo/my-proj",  // Project root
            "session-1",
            vec![ClaudeMessage::new(
                "assistant",
                "claude-opus-4-5-20251101",
                12,
                6,
                "2026-01-20T10:00:00.000Z",
            )],
        )
        .when_run()
        .should_succeed()
        .expect_stdout_json()
        // Should find project by walking up
        .field_contains("/project", "my-proj")
        .field_eq("/opencode/found", json!(true))
        .field_eq("/claude_code/found", json!(true))
        .validate();
}
```

### Example: Testing Aggregation

```rust
/// Test: tokens sum across multiple sessions.
#[test]
fn tokens_sum_across_sessions() {
    Cmd::given()
        .with_project_dir("/repo/my-proj")
        .with_claude_session(
            "/repo/my-proj",
            "session-1",
            vec![ClaudeMessage::new(
                "assistant",
                "claude-opus-4-5-20251101",
                400,  // Input tokens
                200,  // Output tokens
                "2026-01-20T10:00:00.000Z",
            )],
        )
        .with_claude_session(
            "/repo/my-proj",
            "session-2",
            vec![ClaudeMessage::new(
                "assistant",
                "claude-opus-4-5-20251101",
                600,  // Input tokens
                300,  // Output tokens
                "2026-01-21T10:00:00.000Z",
            )],
        )
        .when_run()
        .should_succeed()
        .expect_stdout_json()
        .expect_claude_code(|c| {
            // Should sum: 400 + 600 = 1000, 200 + 300 = 500
            c.tokens("claude-opus-4-5-20251101", 1000, 500)
        });
}
```

### Example: Testing Error Handling

```rust
/// Test: missing jq produces helpful error.
#[test]
fn missing_jq_shows_helpful_error() {
    Cmd::given()
        .with_project_dir("/repo/my-proj")
        .with_opencode_session(...)
        // Force jq check to fail
        .with_env("LLM_USAGE_FORCE_NO_JQ", "1")
        .when_run()
        .should_fail()
        .expect_error_contains("jq");
}
```

### Test Organization

**By Feature**:
- `all_mode.rs` - Tests for `--all` flag
- `date_filters.rs` - Tests for `--from`/`--to`
- `project_flag.rs` - Tests for `--project`

**By Behavior**:
- `project_discovery.rs` - Auto-detection and walking
- `errors.rs` - Error scenarios
- `tokens.rs` - Token aggregation
- `sessions_by_model.rs` - Session counting

**Naming Convention**:
- File: `feature_name.rs`
- Test: `fn behavior_description()`
- Use underscores, be descriptive
- Start with action verb when possible

## Debugging

### Running Tests

```bash
# All tests
cargo test

# Specific test file
cargo test --test project_discovery

# Specific test
cargo test default_mode_discovers_project

# With output
cargo test -- --nocapture

# Show test names without running
cargo test -- --list
```

### Debug Output

**Enable debug mode in script**:
```bash
LLM_USAGE_DEBUG=1 cargo test test_name -- --nocapture
```

This shows:
- Path comparisons
- Directory searches
- Why projects match/don't match

**Inspect test fixtures**:
```rust
#[test]
fn debug_fixtures() {
    let cmd = Cmd::given()
        .with_project_dir("/repo/my-proj")
        .with_opencode_session(...);
    
    // Fixtures are in cmd.temp_dir
    // Add breakpoint here to inspect
    
    cmd.when_run().should_succeed();
}
```

**Print JSON output**:
```rust
.when_run()
.should_succeed()
.expect_stdout_json()
.validate()  // Returns Value
// Can't print here, but can inspect in debugger
```

### Common Issues

**Test fails with "path not found"**:
- Check path mapping in DSL
- Verify fixture generation
- Enable debug mode

**Test fails with "command not found"**:
- Check `llm-usage` script is executable
- Verify path in `CmdGiven::when_run()`

**Test hangs**:
- Check for infinite loops in script
- Verify jq commands complete
- Add timeout (not currently implemented)

## Code Style

### Bash Script (`llm-usage`)

**General**:
```bash
# Use strict mode
set -euo pipefail

# Constants in UPPER_CASE
readonly VERSION="0.1.0"

# Variables in snake_case
local project_path="$1"

# Functions in snake_case
load_opencode_stats() {
    local project_path="$1"
    # ...
}
```

**Quoting**:
```bash
# Always quote variables
echo "$var"
local path="$1"

# Quote command substitution
local result="$(command)"

# Arrays
local files=("$dir"/*.json)
```

**Conditionals**:
```bash
# Use [[ ]] not [ ]
if [[ "$var" == "value" ]]; then
    # ...
fi

# Check file existence
if [[ -f "$file" ]]; then
    # ...
fi
```

**Functions**:
```bash
# Document complex functions
# Load OpenCode stats for a single project
# Args:
#   $1 - project_path: absolute path to project
# Returns:
#   JSON object with stats
load_opencode_stats() {
    local project_path="$1"
    # ...
}
```

### Rust Tests (`cli-tests/`)

**Formatting**:
```bash
# Auto-format
cargo fmt

# Check formatting
cargo fmt -- --check
```

**Linting**:
```bash
# Run clippy
cargo clippy

# Fix automatically
cargo clippy --fix
```

**Style**:
```rust
// Use descriptive names
fn default_mode_discovers_project() { }

// Group related setup
Cmd::given()
    // OpenCode fixtures
    .with_opencode_session(...)
    .with_opencode_session(...)
    
    // Claude fixtures
    .with_claude_session(...)
    
    // Arguments
    .with_arg("--all")
```

## Contributing

### Workflow

1. **Fork and Clone**:
   ```bash
   git clone https://github.com/yourusername/agent-chisels
   cd agent-chisels/tools/llm-usage
   ```

2. **Create Branch**:
   ```bash
   git checkout -b feature/my-feature
   ```

3. **Make Changes**:
   - Edit `llm-usage` script
   - Add/update tests in `cli-tests/tests/`
   - Run tests: `cargo test`

4. **Commit**:
   ```bash
   git add .
   git commit -m "feat: add support for --format flag"
   ```

5. **Push and PR**:
   ```bash
   git push origin feature/my-feature
   # Create PR on GitHub
   ```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add support for CSV output
fix: handle symlinks in project discovery
docs: update ARCHITECTURE.md
test: add tests for date filtering
refactor: simplify token aggregation logic
```

### Adding Features

**Example: Add `--format` flag**

1. **Update script**:
   ```bash
   # In llm-usage
   FORMAT="json"  # Add variable
   
   # Add to CLI parsing
   --format)
       FORMAT="$2"
       shift 2
       ;;
   
   # Update output generation
   if [[ "$FORMAT" == "csv" ]]; then
       # Generate CSV
   else
       # Generate JSON (existing)
   fi
   ```

2. **Add tests**:
   ```rust
   // In cli-tests/tests/format.rs
   #[test]
   fn csv_format_works() {
       Cmd::given()
           .with_project_dir("/repo/my-proj")
           .with_opencode_session(...)
           .with_arg("--format")
           .with_arg("csv")
           .when_run()
           .should_succeed();
       // Assert CSV output
   }
   ```

3. **Update docs**:
   - Update `README.md`
   - Update `GETTING-STARTED.md`
   - Update `ARCHITECTURE.md` if needed

### Testing Checklist

Before submitting PR:

- [ ] All tests pass: `cargo test`
- [ ] Code is formatted: `cargo fmt`
- [ ] No clippy warnings: `cargo clippy`
- [ ] New features have tests
- [ ] Bug fixes have regression tests
- [ ] Documentation updated
- [ ] Manual testing done

### Review Process

1. **Automated Checks**:
   - Tests must pass
   - Code must be formatted
   - No clippy warnings

2. **Code Review**:
   - Maintainer reviews code
   - Provides feedback
   - Approves or requests changes

3. **Merge**:
   - Squash and merge
   - Delete branch

## Advanced Topics

### Extending the DSL

**Add new assertion**:

```rust
// In assertions.rs
impl<'a> OpencodeAssert<'a> {
    pub fn has_data(self) -> Self {
        assert!(
            self.opencode.get("found").unwrap().as_bool().unwrap(),
            "Expected OpenCode data to be found"
        );
        self
    }
}
```

**Add new fixture type**:

```rust
// In dsl/mod.rs
pub struct CustomMessage {
    // Fields
}

impl CmdGiven {
    pub fn with_custom_session(mut self, ...) -> Self {
        // Add to fixtures
        self
    }
}
```

### Performance Testing

```rust
use std::time::Instant;

#[test]
fn performance_large_dataset() {
    let start = Instant::now();
    
    let mut cmd = Cmd::given().with_project_dir("/repo/my-proj");
    
    // Add 1000 sessions
    for i in 0..1000 {
        cmd = cmd.with_opencode_session(
            "/repo/my-proj",
            &format!("ses_{}", i),
            vec![OpencodeMessage::new(...)],
        );
    }
    
    cmd.when_run().should_succeed();
    
    let duration = start.elapsed();
    assert!(duration.as_secs() < 10, "Should complete in <10s");
}
```

### Integration Testing

The current tests are **integration tests** - they test the entire script end-to-end.

For **unit testing** individual bash functions, consider:
- [bats-core](https://github.com/bats-core/bats-core) - Bash testing framework
- [shunit2](https://github.com/kward/shunit2) - xUnit for shell scripts

## Resources

### Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture
- [GETTING-STARTED.md](./GETTING-STARTED.md) - User guide
- [README.md](./README.md) - Quick reference
- [SCHEMA-NOTES.md](./SCHEMA-NOTES.md) - Data formats

### External Resources

- [Bash Best Practices](https://bertvv.github.io/cheat-sheets/Bash.html)
- [jq Manual](https://stedolan.github.io/jq/manual/)
- [Rust Book](https://doc.rust-lang.org/book/)
- [BDD with Rust](https://blog.logrocket.com/behavior-driven-development-in-rust/)

### Tools

- [shellcheck](https://www.shellcheck.net/) - Bash linter
- [shfmt](https://github.com/mvdan/sh) - Bash formatter
- [cargo-watch](https://github.com/watchexec/cargo-watch) - Auto-run tests

## Getting Help

### Questions

- Check existing tests for examples
- Read [ARCHITECTURE.md](./ARCHITECTURE.md) for design decisions
- Search issues on GitHub

### Reporting Bugs

Include:
1. Command that failed
2. Expected vs actual behavior
3. Test output with `--nocapture`
4. OS and version
5. Script version

### Feature Requests

1. Check existing issues
2. Describe use case
3. Propose API if applicable
4. Consider implementing yourself!

---

Happy developing! 🚀
