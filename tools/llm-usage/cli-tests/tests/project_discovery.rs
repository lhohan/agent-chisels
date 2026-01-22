//! Tests for project discovery via directory walking.

use llm_usage_tests::{ClaudeMessage, Cmd, OpencodeMessage};
use serde_json::json;
use std::path::Path;

/// Test: default mode finds project by walking up directories.
#[test]
fn default_mode_discovers_project() {
    // Create a nested directory structure
    let nested_dir = Path::new("/repo/my-proj/src/components");

    Cmd::given()
        .with_project_dir(nested_dir)
        .with_opencode_session(
            "/repo/my-proj",
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
            "/repo/my-proj",
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
        .field_contains("/project", "my-proj")
        .field_eq("/opencode/found", json!(true))
        .field_eq("/claude_code/found", json!(true))
        .validate();
}

/// Test: discovers project when current dir IS the project root.
#[test]
fn discovers_at_project_root() {
    let project_dir = Path::new("/repo/my-proj");

    Cmd::given()
        .with_project_dir(project_dir)
        .with_opencode_session(
            "/repo/my-proj",
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
            "/repo/my-proj",
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
        .field_contains("/project", "my-proj")
        .validate();
}

/// Test: discovers project when in nested subdirectory.
#[test]
fn discovers_in_deeply_nested() {
    let deep_path = Path::new("/repo/my-proj/src/features/auth/components");

    Cmd::given()
        .with_project_dir(deep_path)
        .with_opencode_session(
            "/repo/my-proj",
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
            "/repo/my-proj",
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
        .field_contains("/project", "my-proj")
        .validate();
}
