//! Tests for session counting per model.

use llm_usage_tests::{ClaudeMessage, Cmd, DomainAssertions, OpencodeMessage};

/// Test: sessions_by_model counts per model used (multi-model session).
#[test]
fn multi_model_session_counts_both() {
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
            vec![
                ClaudeMessage::new(
                    "assistant",
                    "claude-opus-4-5-20251101",
                    12,
                    6,
                    "2026-01-20T10:00:00.000Z",
                ),
                ClaudeMessage::new(
                    "assistant",
                    "claude-sonnet-4-20251101",
                    8,
                    4,
                    "2026-01-20T10:01:00.000Z",
                ),
            ],
        )
        .when_run()
        .should_succeed()
        .expect_stdout_json()
        .expect_claude_code(|c| {
            c.sessions(1) // 1 session file
                .sessions_by_model("claude-opus-4-5-20251101", 1) // Used in that session
                .sessions_by_model("claude-sonnet-4-20251101", 1) // Also used in same session
        });
}

/// Test: single model session only counts once.
#[test]
fn single_model_session_counts_once() {
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
        .expect_claude_code(|c| c.sessions(1).sessions_by_model("claude-opus-4-5-20251101", 1));
}

/// Test: multiple sessions with same model.
#[test]
fn multiple_sessions_same_model() {
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
        .with_claude_session(
            "/repo/my-proj",
            "session-2",
            vec![ClaudeMessage::new(
                "assistant",
                "claude-opus-4-5-20251101",
                15,
                7,
                "2026-01-21T10:00:00.000Z",
            )],
        )
        .with_claude_session(
            "/repo/my-proj",
            "session-3",
            vec![ClaudeMessage::new(
                "assistant",
                "claude-opus-4-5-20251101",
                18,
                9,
                "2026-01-22T10:00:00.000Z",
            )],
        )
        .when_run()
        .should_succeed()
        .expect_stdout_json()
        .expect_claude_code(|c| {
            c.sessions(3) // 3 session files
                .sessions_by_model("claude-opus-4-5-20251101", 3) // Used in all 3
        });
}
