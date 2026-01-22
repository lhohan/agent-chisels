# Implementation Plan

**Project**: llm-usage
**Generated**: 2026-01-22T00:00:00Z

## Technical Context & Standards
*Detected Stack & Patterns*
- **Architecture**: Unix CLI utility (single-purpose; JSON to stdout; pipeable)
- **Implementation**: Bash script (jq-driven parsing)
- **Testing**: Rust-based CLI acceptance tests using a fluent DSL (inspired by `~/dev/rust/time-tracker`)
- **Test crates (expected)**: `assert_cmd`, `assert_fs`, `predicates`, `rstest`, `serde_json`
- **Data sources**:
  - OpenCode: `~/.local/share/opencode/storage/`
  - Claude Code: `~/.claude/projects/`
- **Critical testability requirement**: Script supports **env var overrides** for data stores:
  - `LLM_USAGE_OPENCODE_STORAGE`
  - `LLM_USAGE_CLAUDE_PROJECTS`
- **CLI execution in tests**: `std::process::Command::new(script_path)` (not `cargo_bin`)
- **Universal DSL Testing Guide compliance**:
  - Setup → Action → Assertion phases
  - Fluent chaining API
  - Distinct types per phase to prevent misuse
  - Temp resources kept alive through assertions (RAII / ownership)

---

## Phase 1: Schema Reconnaissance (must happen first)

- [ ] **Confirm OpenCode JSON schema + timestamp fields** (ref: PRD "Data sources", "Usage over time")
  Task ID: phase-1-schema-reconnaissance-01
  > **Implementation**: Inspect real files under `~/.local/share/opencode/storage/`.
  > **Details**:
  > - Identify JSON paths for:
  >   - project worktree path (expected: `.worktree`)
  >   - session identifier and created-at timestamp (confirm actual fields)
  >   - message model identity (confirm `.modelID` / `.providerID` etc.)
  >   - message token usage shape (confirm `.tokens.input` / `.tokens.output` or alternative)
  > - Produce a short mapping table (field → json path) to drive implementation + tests.
  > - Decide which timestamp to use for daily breakdown:
  >   - Prefer message timestamp if available; otherwise session timestamp.

- [ ] **Confirm Claude Code JSONL schema + timestamp fields** (ref: PRD "Data sources", "Usage over time")
  Task ID: phase-1-schema-reconnaissance-02
  > **Implementation**: Inspect real files under `~/.claude/projects/<encoded-path>/*.jsonl`.
  > **Details**:
  > - Identify JSON paths per JSONL line for:
  >   - model (expected: `.message.model`)
  >   - usage tokens (expected: `.message.usage.input_tokens` / `.message.usage.output_tokens`)
  >   - timestamp (confirm actual field; may not be under `.message.*`)
  > - Confirm "session" definition:
  >   - 1 JSONL file == 1 session (as per PRD)
  > - Confirm how to compute `sessions_by_model` when multiple models appear in one session:
  >   - **Decision (confirmed)**: count the session once per model used.

- [ ] **Update PRD-derived assumptions in a short notes doc** (ref: PRD "Architecture & Design")
  Task ID: phase-1-schema-reconnaissance-03
  > **Implementation**: Plan to create `tools/llm-usage/SCHEMA-NOTES.md`.
  > **Details**:
  > - Record the field/path mapping discovered above.
  > - Record any gotchas (missing fields, nulls, alternative shapes).
  > - This becomes the contract for later test fixtures.

---

## Phase 2: Tool & Directory Scaffolding

- [ ] **Create tool directory skeleton** (ref: PRD "Technical Constraints")
  Task ID: phase-2-scaffolding-01
  > **Implementation**: Create `tools/llm-usage/`.
  > **Details**:
  > - Place the executable at `tools/llm-usage/llm-usage` (no `.sh`).
  > - Reserve `tools/llm-usage/cli-tests/` for Rust tests.

- [ ] **Define script interface + env overrides contract** (ref: PRD "CLI interface", "Technical Constraints")
  Task ID: phase-2-scaffolding-02
  > **Implementation**: Plan edits in `tools/llm-usage/llm-usage`.
  > **Details**:
  > - Support flags:
  >   - `--all`, `--project PATH`, `--from YYYY-MM-DD`, `--to YYYY-MM-DD`
  > - Support env overrides:
  >   - `LLM_USAGE_OPENCODE_STORAGE` defaults to `$HOME/.local/share/opencode/storage`
  >   - `LLM_USAGE_CLAUDE_PROJECTS` defaults to `$HOME/.claude/projects`
  > - These env vars are required for deterministic Rust acceptance tests.

---

## Phase 3: Nix Flake (scoped to tools/llm-usage)

- [ ] **Add Nix flake providing Rust toolchain for cli-tests** (ref: request "Add a nixflake … only in that directory")
  Task ID: phase-3-nix-flake-01
  > **Implementation**: Create `tools/llm-usage/flake.nix` (and `flake.lock` on first use).
  > **Details**:
  > - Provide a devShell including:
  >   - `cargo`, `rustc`, `clippy`, `rustfmt`
  >   - plus any test runtime tools you want pinned (optional: `jq`)
  > - Ensure usage instructions are documented in `tools/llm-usage/README.md`:
  >   - `nix develop`
  >   - `cargo test` (from `cli-tests/`)

---

## Phase 4: Rust CLI Test Harness (TDD foundation; Universal DSL explicit)

- [ ] **Create isolated Rust test crate** (ref: time-tracker patterns; avoid repo-wide Rust config)
  Task ID: phase-4-rust-test-harness-01
  > **Implementation**: Create `tools/llm-usage/cli-tests/Cargo.toml`.
  > **Details**:
  > - Add dev deps: `assert_cmd`, `assert_fs`, `predicates`, `rstest`
  > - Add deps: `serde`, `serde_json`

- [ ] **Implement typed-phase DSL entry point** (ref: Universal DSL "Entry Point Pattern", "distinct types per phase")
  Task ID: phase-4-rust-test-harness-02
  > **Implementation**: Create `tools/llm-usage/cli-tests/src/dsl/mod.rs`.
  > **Details**:
  > - Provide:
  >   - `pub struct Cmd;`
  >   - `pub struct CmdGiven { ... }` (setup state + temp dirs)
  >   - `pub struct CmdWhen { ... }` (configured command ready to run)
  >   - `pub struct CmdThen { ... }` (result + temp resources kept alive)
  > - API shape:
  >   - `Cmd::given() -> CmdGiven`
  >   - `CmdGiven::when_run(self) -> CmdThen`
  > - **Resource lifetime requirement**:
  >   - `CmdThen` must own `assert_fs::TempDir` (or `Arc<TempDir>`) so fixtures persist through assertions.

- [ ] **Implement fixture builders for OpenCode + Claude stores** (ref: Universal DSL "Input Source Management")
  Task ID: phase-4-rust-test-harness-03
  > **Implementation**: Add `tools/llm-usage/cli-tests/src/fixtures/{opencode.rs,claude.rs}`.
  > **Details**:
  > - Build realistic fixture directory trees under temp dirs matching real store layouts.
  > - Provide helper methods on `CmdGiven`:
  >   - `.with_opencode_project(worktree_path: &str, project_id_hint: &str) -> CmdGiven`
  >   - `.with_opencode_session(project_id: ..., session_id: ..., messages: ...) -> CmdGiven`
  >   - `.with_claude_project(project_path: &str) -> CmdGiven` (handles encoded dir)
  >   - `.with_claude_session(project_path: &str, session_file: &str, jsonl_lines: &[&str]) -> CmdGiven`
  > - Fixtures must follow the schema confirmed in Phase 1 (timestamps + token fields).

- [ ] **Wire script execution via Command::new(script_path)** (ref: user req "ONLY consider CLI tests…")
  Task ID: phase-4-rust-test-harness-04
  > **Implementation**: Create `tools/llm-usage/cli-tests/src/exec.rs`.
  > **Details**:
  > - Locate script path as `../llm-usage` relative to crate root.
  > - Run with:
  >   - `Command::new(script_path)`
  >   - `current_dir(...)` set to chosen workdir
  >   - env vars set for fixture dirs:
  >     - `LLM_USAGE_OPENCODE_STORAGE=<temp>/opencode/storage`
  >     - `LLM_USAGE_CLAUDE_PROJECTS=<temp>/claude/projects`
  > - Capture stdout/stderr/exit code.

- [ ] **Implement assertion DSL (Then phase) + JSON helpers** (ref: Universal DSL "Assertion Phase Patterns")
  Task ID: phase-4-rust-test-harness-05
  > **Implementation**: Create `tools/llm-usage/cli-tests/src/assertions.rs`.
  > **Details**:
  > - `CmdThen` methods:
  >   - `.should_succeed() -> CmdThen`
  >   - `.should_fail() -> CmdThen`
  >   - `.expect_error_contains(str) -> CmdThen`
  >   - `.expect_stdout_json() -> JsonAssert` (parses stdout into `serde_json::Value`)
  > - `JsonAssert` methods:
  >   - `.field_eq(path: &str, expected: serde_json::Value) -> JsonAssert`
  >   - `.validate() -> CmdThen`
  > - Provide domain assertions:
  >   - `.expect_opencode(|o| o.sessions(…).sessions_by_model(…).tokens(…))`
  >   - `.expect_claude_code(|c| ...)`

### Example (included for readability; not a full implementation)
```rust
use llm_usage_tests::dsl::Cmd;
use serde_json::json;

#[test]
fn current_project_outputs_json() {
    Cmd::given()
        .with_project_dir("/repo/my-proj")
        .with_opencode_project("/repo/my-proj")
        .with_claude_project("/repo/my-proj")
        .when_run()
        .should_succeed()
        .expect_stdout_json()
            .field_eq(".project", json!("/repo/my-proj"))
            .field_eq(".opencode.found", json!(true))
            .validate();
}
```

---

## Phase 5: Write Acceptance Tests First (RED)

- [ ] **Test: default mode finds project by walking up directories** (ref: PRD "Walk up parent directories")
  Task ID: phase-5-tests-red-01
  > **Implementation**: Create `tools/llm-usage/cli-tests/tests/project_discovery.rs`.
  > **Details**:
  > - Set `current_dir` to a nested path under a fixture project.
  > - Assert `.project` resolves to the intended root.
  > - Assert `found` booleans are correct per source.

- [ ] **Test: sessions_by_model counts per model used (multi-model session)** (ref: PRD "Session counts per model"; user decision)
  Task ID: phase-5-tests-red-02
  > **Implementation**: Create `tools/llm-usage/cli-tests/tests/sessions_by_model.rs`.
  > **Details**:
  > - Create a single session containing messages from 2 models.
  > - Expect:
  >   - `sessions == 1`
  >   - `sessions_by_model.modelA == 1`
  >   - `sessions_by_model.modelB == 1`

- [ ] **Test: token aggregation per model (input/output)** (ref: PRD "Token usage per model")
  Task ID: phase-5-tests-red-03
  > **Implementation**: Create `tools/llm-usage/cli-tests/tests/tokens.rs`.
  > **Details**:
  > - Build messages with known token counts.
  > - Validate `.tokens.<model>.input` and `.tokens.<model>.output`.

- [ ] **Test: daily usage breakdown** (ref: PRD "Usage over time (daily breakdown)")
  Task ID: phase-5-tests-red-04
  > **Implementation**: Create `tools/llm-usage/cli-tests/tests/usage_by_date.rs`.
  > **Details**:
  > - Use timestamps confirmed in Phase 1 to craft fixtures across multiple dates.
  > - Assert `.usage_by_date["YYYY-MM-DD"].sessions/messages` totals.

- [ ] **Test: date filters --from/--to** (ref: PRD "Configurable date range")
  Task ID: phase-5-tests-red-05
  > **Implementation**: Create `tools/llm-usage/cli-tests/tests/date_filters.rs`.
  > **Details**:
  > - Use `rstest` for table-driven cases.
  > - Validate filtered counts and `time_range` echo in output.

- [ ] **Test: --project PATH** (ref: PRD "Should have")
  Task ID: phase-5-tests-red-06
  > **Implementation**: Create `tools/llm-usage/cli-tests/tests/project_flag.rs`.
  > **Details**:
  > - Ensure explicit project path bypasses current_dir discovery.

- [ ] **Test: --all aggregates across projects** (ref: PRD "--all flag")
  Task ID: phase-5-tests-red-07
  > **Implementation**: Create `tools/llm-usage/cli-tests/tests/all_mode.rs`.
  > **Details**:
  > - Create 2+ projects in fixtures for each source.
  > - Assert output structure is "all projects" mode (exact JSON schema to be decided in implementation; must remain pipeable and stable).

- [ ] **Test: missing jq produces helpful error** (ref: PRD "No jq installed")
  Task ID: phase-5-tests-red-08
  > **Implementation**: Create `tools/llm-usage/cli-tests/tests/errors.rs`.
  > **Details**:
  > - Execute with PATH modified to hide jq (or set env to simulate).
  > - Assert non-zero exit and stderr includes install hints.

- [ ] **Test: no data found emits helpful message listing nearby projects** (ref: PRD "Error message lists nearby projects")
  Task ID: phase-5-tests-red-09
  > **Implementation**: Extend `tools/llm-usage/cli-tests/tests/errors.rs`.
  > **Details**:
  > - Ensure fixtures contain other projects but not the requested one.
  > - Assert stderr suggests available projects.

---

## Phase 6: Implement Bash Script to Make Tests Pass (GREEN)

- [ ] **Implement CLI parsing + env overrides** (ref: PRD "CLI interface"; test harness requirements)
  Task ID: phase-6-implementation-green-01
  > **Implementation**: Edit `tools/llm-usage/llm-usage`.
  > **Details**:
  > - Parse flags (no external deps beyond jq).
  > - Default data roots from env or HOME.
  > - Normalize paths (absolute paths) for consistent matching.

- [ ] **Implement OpenCode loader (project → sessions → messages)** (ref: PRD "OpenCode data sources")
  Task ID: phase-6-implementation-green-02
  > **Implementation**: Edit `tools/llm-usage/llm-usage`.
  > **Details**:
  > - Use schema mapping from Phase 1.
  > - Aggregate:
  >   - sessions total
  >   - sessions_by_model (count per model used within session)
  >   - messages_by_model
  >   - tokens per model
  >   - usage_by_date
  > - Handle missing dirs by returning `found: false` or zeroed stats as appropriate.

- [ ] **Implement Claude Code loader (encoded path → jsonl sessions)** (ref: PRD "Claude Code data sources")
  Task ID: phase-6-implementation-green-03
  > **Implementation**: Edit `tools/llm-usage/llm-usage`.
  > **Details**:
  > - Encode project path to Claude directory name.
  > - Session == file; model usage derived from lines.
  > - sessions_by_model: session counts once per model used in that file.

- [ ] **Implement date filtering** (ref: PRD "--from/--to")
  Task ID: phase-6-implementation-green-04
  > **Implementation**: Edit `tools/llm-usage/llm-usage`.
  > **Details**:
  > - Filter at source record level (messages/sessions) before aggregation, or filter aggregated daily buckets (must match tests).
  > - Use consistent timezone handling (prefer UTC).

- [ ] **Implement JSON output assembly + validation** (ref: PRD "JSON output structure")
  Task ID: phase-6-implementation-green-05
  > **Implementation**: Edit `tools/llm-usage/llm-usage`.
  > **Details**:
  > - Output stable JSON object with:
  >   - `generated_at`, `project`, `time_range`, `opencode`, `claude_code`
  > - Ensure output is always valid JSON (use jq to construct, not string concatenation).

- [ ] **Implement no-project-found and nearby-project suggestions** (ref: PRD "helpful message lists nearby projects")
  Task ID: phase-6-implementation-green-06
  > **Implementation**: Edit `tools/llm-usage/llm-usage`.
  > **Details**:
  > - If not `--all` and no matching project, exit non-zero with suggestions.
  > - Suggestions include nearest matching worktrees (OpenCode) and existing Claude encoded dirs.

---

## Phase 7: Refactor & Developer Ergonomics

- [ ] **Refactor Bash script into well-named functions** (ref: PRD "Modular functions")
  Task ID: phase-7-refactor-01
  > **Implementation**: Edit `tools/llm-usage/llm-usage`.
  > **Details**:
  > - Functions: `find_project_root`, `load_opencode_stats`, `load_claude_code_stats`, `aggregate_by_model`, `filter_by_date_range`, `output_json`.
  > - Keep behavior constant; tests must remain green.

- [ ] **Document Nix + test commands + future just recipe hook** (ref: user note about just/gist)
  Task ID: phase-7-refactor-02
  > **Implementation**: Create/Edit `tools/llm-usage/README.md`.
  > **Details**:
  > - Document:
  >   - `nix develop`
  >   - `cd tools/llm-usage/cli-tests && cargo test`
  > - Leave a placeholder section for your future `just test` recipe / gist integration.

---

*Generated by Clavix /clavix:plan*
