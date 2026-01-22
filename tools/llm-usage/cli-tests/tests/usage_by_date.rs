//! Tests for daily usage breakdown.

use llm_usage_tests::{ClaudeMessage, Cmd, DomainAssertions, OpencodeMessage};
use serde_json::json;

/// Test: daily usage breakdown.
#[test]
fn daily_usage_breakdown() {
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
        .when_run()
        .should_succeed()
        .expect_stdout_json()
        .field_eq("/opencode/usage_by_date/2026-01-20/messages", json!(1))
        .validate();
}

/// Test: usage by date respects filters.
#[test]
fn usage_by_date_respects_filters() {
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
        .when_run()
        .should_succeed()
        .expect_stdout_json()
        .expect_opencode(|o| o)
        .expect_claude_code(|c| c);
}
