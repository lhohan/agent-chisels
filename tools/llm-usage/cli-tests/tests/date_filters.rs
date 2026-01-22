//! Tests for date filtering (--from/--to).

use llm_usage_tests::{ClaudeMessage, Cmd, OpencodeMessage};
use serde_json::json;
use rstest::rstest;

/// Test: date filters --from/--to.
#[rstest]
#[case("2026-01-01", "2026-01-31", 5)]
#[case("2026-01-20", "2026-01-25", 3)]
#[case("2026-01-01", "2026-01-10", 0)] // Outside range
fn date_filter_respects_range(#[case] from: &str, #[case] to: &str, #[case] _expected: u64) {
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
        .with_arg("--from")
        .with_arg(from)
        .with_arg("--to")
        .with_arg(to)
        .when_run()
        .should_succeed()
        .expect_stdout_json()
            .field_eq("/time_range/from", json!(from))
            .field_eq("/time_range/to", json!(to))
            .validate();
}

/// Test: time range is echoed in output.
#[test]
fn time_range_echoed_in_output() {
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
            .field_eq("/time_range/from", json!(""))
            .field_eq("/time_range/to", json!(""))
            .validate();
}
