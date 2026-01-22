//! Tests for --project PATH flag.

use llm_usage_tests::{ClaudeMessage, Cmd, OpencodeMessage};

/// Test: --project PATH bypasses current_dir discovery.
#[test]
fn project_flag_bypasses_discovery() {
    Cmd::given()
        .with_project_dir("/some/other/path") // Not a project
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
        .with_project_arg("/repo/my-proj")
        .when_run()
        .should_succeed()
        .expect_stdout_json()
        .field_contains("/project", "my-proj")
        .validate();
}

/// Test: --project with non-existent path.
#[test]
fn project_flag_nonexistent_path() {
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
        .with_project_arg("/repo/my-proj")
        .when_run()
        .should_succeed()
        .expect_stdout_json()
        .field_contains("/project", "my-proj")
        .validate();
}
