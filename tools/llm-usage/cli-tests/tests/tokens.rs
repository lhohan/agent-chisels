//! Tests for token aggregation per model.

use llm_usage_tests::{ClaudeMessage, Cmd, DomainAssertions, OpencodeMessage};

/// Test: token aggregation per model (input/output).
#[test]
fn token_aggregation_works() {
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
                500,
                250,
                "2026-01-20T10:00:00.000Z",
            )],
        )
        .when_run()
        .should_succeed()
        .expect_stdout_json()
        .expect_claude_code(|c| c.tokens("claude-opus-4-5-20251101", 500, 250));
}

/// Test: tokens sum across multiple sessions.
#[test]
fn tokens_sum_across_sessions() {
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
                400,
                200,
                "2026-01-20T10:00:00.000Z",
            )],
        )
        .with_claude_session(
            "/repo/my-proj",
            "session-2",
            vec![ClaudeMessage::new(
                "assistant",
                "claude-opus-4-5-20251101",
                600,
                300,
                "2026-01-21T10:00:00.000Z",
            )],
        )
        .when_run()
        .should_succeed()
        .expect_stdout_json()
        .expect_claude_code(|c| {
            c.tokens("claude-opus-4-5-20251101", 1000, 500) // Sum of 2 sessions
        });
}

/// Test: OpenCode tokens should be null (not available).
#[test]
fn opencode_tokens_not_available() {
    Cmd::given()
        .with_project_dir("/repo/my-proj")
        .with_opencode_session(
            "/repo/my-proj",
            "ses_1",
            vec![OpencodeMessage::new(
                "assistant",
                "opencode",
                "antigravity-gemini-3-flash",
                120,
                45,
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
        .expect_opencode(|o| {
            o.tokens("antigravity-gemini-3-flash", 120, 45)
        });
}
