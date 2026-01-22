//! Tests for error handling (missing jq, no data found).

use llm_usage_tests::{ClaudeMessage, Cmd, OpencodeMessage};

/// Test: missing jq produces helpful error.
#[test]
fn missing_jq_shows_helpful_error() {
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
        .with_env("LLM_USAGE_FORCE_NO_JQ", "1")
        .when_run()
        .should_fail()
        .expect_error_contains("jq");
}

/// Test: no data found emits helpful message.
#[test]
fn no_data_found_helpful_message() {
    Cmd::given()
        .with_project_dir("/repo/unknown-proj") // No fixtures for this
        .when_run()
        .should_fail()
        .expect_error_contains("No LLM usage data found");
}

/// Test: no data found lists nearby projects.
#[test]
fn no_data_found_suggests_projects() {
    Cmd::given()
        .with_project_dir("/repo/empty-proj")
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
        .should_fail()
        .expect_error_contains("my-proj"); // Should suggest nearby project
}
