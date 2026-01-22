# Rust CLI DSL Example

Example of a behaviour-driven DSL for CLI testing using `assert_cmd` for process invocation and plain assertions for verification.

## Dependencies

```toml
[dev-dependencies]
assert_cmd = "3.0"
predicates = "3.0"
tempfile = "4.0"
```

## DSL Structure

```rust
use assert_cmd::Command;
use std::path::PathBuf;

struct CliContext {
    temp_dir: PathBuf,
    config_file: Option<PathBuf>,
}

impl CliContext {
    fn new() -> Self {
        Self {
            temp_dir: tempfile::tempdir().unwrap().into_path(),
            config_file: None,
        }
    }

    fn with_config(mut self, config: &str) -> Self {
        let config_path = self.temp_dir.join("config.toml");
        std::fs::write(&config_path, config).unwrap();
        self.config_file = Some(config_path);
        self
    }

    fn app(&self) -> Command {
        let mut cmd = Command::new(cargo_bin!("my-cli-app"));
        if let Some(ref config) = self.config_file {
            cmd.arg("--config").arg(config);
        }
        cmd
    }
}
```

## Given: Preconditions

```rust
fn given_temp_directory() -> CliContext {
    CliContext::new()
}

fn given_config_file(ctx: CliContext, config: &str) -> CliContext {
    ctx.with_config(config)
}
```

## When: Actions

```rust
fn when_cli_runs(ctx: &CliContext, args: &[&str]) -> assert_cmd::Result<assert_cmd::Output> {
    let mut cmd = ctx.app();
    cmd.args(args);
    cmd.output()
}

fn when_cli_panics(ctx: &CliContext, args: &[&str]) -> assert_cmd::Result<()> {
    let mut cmd = ctx.app();
    cmd.args(args);
    cmd.assert().try_wait()
}
```

## Plain Assertions

```rust
#[test]
fn cli_shows_help() {
    let ctx = given_temp_directory();
    let output = when_cli_runs(&ctx, &["--help"]).unwrap();

    assert!(output.status.success());
    assert!(String::from_utf8_lossy(&output.stdout)
        .contains("Usage:"));
}

#[test]
fn cli_with_invalid_config_shows_error() {
    let ctx = given_config_file(ctx, r#"
invalid_toml = this is not valid
"#);
    let result = when_cli_runs(&ctx, &["--help"]);

    assert!(result.is_err());
}

#[test]
fn cli_fails_without_required_args() {
    let ctx = given_temp_directory();
    let output = when_cli_runs(&ctx, &["process"]).unwrap_err();

    assert!(!output.status.success());
    assert!(String::from_utf8_lossy(&output.stderr)
        .contains("error: missing required argument"));
}
```

## Full Example Test

```rust
use assert_cmd::Command;
use predicates::prelude::*;

#[test]
fn test_cli_greets_user() {
    let ctx = given_temp_directory();

    let output = when_cli_runs(&ctx, &["greet", "--name", "Alice"]).unwrap();

    assert!(output.status.success());
    assert_eq!(
        String::from_utf8_lossy(&output.stdout).trim(),
        "Hello, Alice!"
    );
}

#[test]
fn test_cli_with_json_output() {
    let ctx = given_temp_directory();

    let output = when_cli_runs(&ctx, &["status", "--format", "json"]).unwrap();

    assert!(output.status.success());
    let json: serde_json::Value =
        serde_json::from_str(&String::from_utf8_lossy(&output.stdout)).unwrap();
    assert_eq!(json["status"], "ok");
}

#[test]
fn test_cli_verbose_flag() {
    let ctx = given_temp_directory();

    let output = when_cli_runs(&ctx, &["--verbose", "list"]).unwrap();

    assert!(output.status.success());
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("Debug:"));
}
```

## Composition Pattern

```rust
fn given_cli_with_config(config: &str) -> CliContext {
    given_temp_directory().with_config(config)
}

fn when_cli_processes(ctx: &CliContext, input: &str) -> assert_cmd::Result<assert_cmd::Output> {
    let mut cmd = ctx.app();
    cmd.arg("process").stdin(input.as_bytes());
    cmd.output()
}

// Usage
#[test]
fn test_full_workflow() {
    let config = given_cli_with_config(r#"
[server]
port = 8080
host = "localhost"
"#);

    let output = when_cli_processes(&config, "test data").unwrap();
    assert!(output.status.success());
}
```

## Key Design Choices

| Choice | Rationale |
|--------|-----------|
| Plain `assert!` / `assert_eq!` | Minimal abstraction; failures show clear source locations |
| `assert_cmd::Result<Output>` | Error handling for missing binaries, not assertion results |
| Context struct for temp dir | Automatic cleanup; isolation between tests |
| No custom matchers | Keep dependencies minimal; standard assertions suffice |
