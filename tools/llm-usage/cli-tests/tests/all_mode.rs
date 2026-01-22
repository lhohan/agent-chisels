//! Tests for --all mode (aggregates across all projects).

use llm_usage_tests::{ClaudeMessage, Cmd, DomainAssertions, OpencodeMessage};
use serde_json::Value;

/// Test: --all aggregates across projects.
#[test]
fn all_mode_aggregates_all() {
    Cmd::given()
        .with_project_dir("/repo/my-proj")
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
        .with_opencode_session(
            "/repo/other-proj",
            "ses_2",
            vec![OpencodeMessage::new(
                "assistant",
                "opencode",
                "gpt-4",
                20,
                10,
                1700003600000,
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
        .with_claude_session(
            "/repo/other-proj",
            "session-2",
            vec![ClaudeMessage::new(
                "assistant",
                "claude-opus-4-5-20251101",
                15,
                7,
                "2026-01-21T10:00:00.000Z",
            )],
        )
        .with_arg("--all")
        .when_run()
        .should_succeed()
        .expect_stdout_json()
        .expect_opencode(|o| o.sessions(2).messages(2))
        .expect_claude_code(|c| c.sessions(2).messages(2));
}

/// Test: all mode works when no specific project is targeted.
#[test]
fn all_mode_no_specific_project() {
    Cmd::given()
        .with_project_dir("/repo/my-proj")
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
        .with_arg("--all")
        .when_run()
        .should_succeed()
        .expect_stdout_json()
        .field_eq("/project", Value::String("".to_string())) // No specific project in --all mode
        .validate();
}
