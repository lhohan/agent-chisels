//! Typed-phase DSL for CLI testing
//!
//! This module provides a fluent API for testing the llm-usage script:
//! - `Cmd::given()` -> `CmdGiven` (setup phase)
//! - `CmdGiven::when_run()` -> `CmdThen` (execution phase)
//! - `CmdThen::assert_*()` -> assertions
//!
//! Resource lifetime requirement: `CmdThen` owns `TempDir` so fixtures persist through assertions.

use std::path::{Path, PathBuf};

use assert_fs::TempDir;
use serde_json::Value;

/// Entry point for the DSL - creates a setup context.
pub struct Cmd;

impl Cmd {
    /// Begin test setup with a temporary directory.
    pub fn given() -> CmdGiven {
        CmdGiven {
            temp_dir: TempDir::new().expect("Failed to create temp dir"),
            project_path: None,
            opencode_projects: Vec::new(),
            claude_projects: Vec::new(),
            env_vars: Vec::new(),
            args: Vec::new(),
        }
    }
}

enum CmdArg {
    Raw(String),
    Path(PathBuf),
}

/// OpenCode message fixture for tests.
pub struct OpencodeMessage {
    pub role: String,
    pub provider_id: String,
    pub model_id: String,
    pub input_tokens: u64,
    pub output_tokens: u64,
    pub created_ms: i64,
}

impl OpencodeMessage {
    pub fn new(
        role: &str,
        provider_id: &str,
        model_id: &str,
        input_tokens: u64,
        output_tokens: u64,
        created_ms: i64,
    ) -> Self {
        Self {
            role: role.to_string(),
            provider_id: provider_id.to_string(),
            model_id: model_id.to_string(),
            input_tokens,
            output_tokens,
            created_ms,
        }
    }
}

/// Claude Code message fixture for tests.
pub struct ClaudeMessage {
    pub role: String,
    pub model: String,
    pub input_tokens: u64,
    pub output_tokens: u64,
    pub timestamp: String,
}

impl ClaudeMessage {
    pub fn new(
        role: &str,
        model: &str,
        input_tokens: u64,
        output_tokens: u64,
        timestamp: &str,
    ) -> Self {
        Self {
            role: role.to_string(),
            model: model.to_string(),
            input_tokens,
            output_tokens,
            timestamp: timestamp.to_string(),
        }
    }
}

/// Setup phase - configure fixtures and environment.
pub struct CmdGiven {
    temp_dir: TempDir,
    project_path: Option<PathBuf>,
    opencode_projects: Vec<OpencodeProjectBuilder>,
    claude_projects: Vec<ClaudeProjectBuilder>,
    env_vars: Vec<(String, String)>,
    args: Vec<CmdArg>,
}

impl CmdGiven {
    /// Set the current working directory / project path.
    pub fn with_project_dir<P: Into<PathBuf>>(mut self, path: P) -> Self {
        self.project_path = Some(path.into());
        self
    }

    /// Add an OpenCode project fixture.
    pub fn with_opencode_project<P: Into<PathBuf>>(
        mut self,
        worktree_path: &str,
        project_id_hint: &str,
    ) -> Self {
        if !self
            .opencode_projects
            .iter()
            .any(|p| p.worktree_path == worktree_path)
        {
            self.opencode_projects.push(OpencodeProjectBuilder {
                worktree_path: worktree_path.to_string(),
                project_id_hint: project_id_hint.to_string(),
                sessions: Vec::new(),
            });
        }
        self
    }

    /// Add an OpenCode session with messages.
    pub fn with_opencode_session(
        mut self,
        worktree_path: &str,
        session_id: &str,
        messages: Vec<OpencodeMessage>,
    ) -> Self {
        if !self
            .opencode_projects
            .iter()
            .any(|p| p.worktree_path == worktree_path)
        {
            self.opencode_projects.push(OpencodeProjectBuilder {
                worktree_path: worktree_path.to_string(),
                project_id_hint: worktree_path.to_string(),
                sessions: Vec::new(),
            });
        }

        if let Some(project) = self
            .opencode_projects
            .iter_mut()
            .find(|p| p.worktree_path == worktree_path)
        {
            project.sessions.push(OpencodeSessionBuilder {
                session_id: session_id.to_string(),
                messages: messages
                    .into_iter()
                    .map(|msg| OpencodeMessageBuilder {
                        role: msg.role,
                        provider_id: msg.provider_id,
                        model_id: msg.model_id,
                        input_tokens: msg.input_tokens,
                        output_tokens: msg.output_tokens,
                        created_ms: msg.created_ms,
                    })
                    .collect(),
            });
        }

        self
    }

    /// Add a Claude Code project fixture.
    pub fn with_claude_project<P: Into<PathBuf>>(mut self, project_path: P) -> Self {
        let project_path = project_path.into();
        if !self
            .claude_projects
            .iter()
            .any(|p| p.project_path == project_path)
        {
            self.claude_projects.push(ClaudeProjectBuilder {
                project_path,
                sessions: Vec::new(),
            });
        }
        self
    }

    /// Add a Claude Code session with messages.
    pub fn with_claude_session<P: Into<PathBuf>>(
        mut self,
        project_path: P,
        session_id: &str,
        messages: Vec<ClaudeMessage>,
    ) -> Self {
        let project_path = project_path.into();
        if !self
            .claude_projects
            .iter()
            .any(|p| p.project_path == project_path)
        {
            self.claude_projects.push(ClaudeProjectBuilder {
                project_path: project_path.clone(),
                sessions: Vec::new(),
            });
        }

        if let Some(project) = self
            .claude_projects
            .iter_mut()
            .find(|p| p.project_path == project_path)
        {
            project.sessions.push(ClaudeSessionBuilder {
                session_id: session_id.to_string(),
                messages: messages
                    .into_iter()
                    .map(|msg| ClaudeMessageBuilder {
                        role: msg.role,
                        model: msg.model,
                        input_tokens: msg.input_tokens,
                        output_tokens: msg.output_tokens,
                        timestamp: msg.timestamp,
                    })
                    .collect(),
            });
        }

        self
    }

    /// Set an environment variable for the command.
    pub fn with_env<K: Into<String>, V: Into<String>>(mut self, key: K, value: V) -> Self {
        self.env_vars.push((key.into(), value.into()));
        self
    }

    /// Add a raw CLI argument.
    pub fn with_arg<S: Into<String>>(mut self, arg: S) -> Self {
        self.args.push(CmdArg::Raw(arg.into()));
        self
    }

    /// Add a --project argument with a path that will be mapped into the workspace.
    pub fn with_project_arg<P: Into<PathBuf>>(mut self, path: P) -> Self {
        self.args.push(CmdArg::Raw("--project".to_string()));
        self.args.push(CmdArg::Path(path.into()));
        self
    }

    /// Execute the command and enter assertion phase.
    pub fn when_run(self) -> CmdThen {
        let script_path = {
            // Find the script relative to the crate root
            let crate_root = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
            crate_root.join("..").join("llm-usage")
        };

        let mut cmd = std::process::Command::new(&script_path);

        let temp_dir_path = self.temp_dir.path().to_path_buf();
        let workspace_root = temp_dir_path.join("workspace");
        std::fs::create_dir_all(&workspace_root).expect("Create workspace root");

        // Set working directory
        if let Some(ref proj_path) = self.project_path {
            let mapped = map_path(proj_path, &workspace_root);
            std::fs::create_dir_all(&mapped).expect("Create project dir");
            cmd.current_dir(&mapped);
        }

        // Set environment variables
        let opencode_storage = temp_dir_path.join("opencode").join("storage");
        let claude_projects = temp_dir_path.join("claude").join("projects");

        // Create directory structure
        std::fs::create_dir_all(&opencode_storage).expect("Create opencode storage");
        std::fs::create_dir_all(&claude_projects).expect("Create claude projects");

        cmd.env(
            "LLM_USAGE_OPENCODE_STORAGE",
            opencode_storage.to_string_lossy().to_string(),
        );
        cmd.env(
            "LLM_USAGE_CLAUDE_PROJECTS",
            claude_projects.to_string_lossy().to_string(),
        );

        // User-provided env vars
        for (key, value) in self.env_vars {
            cmd.env(key, value);
        }

        // Build OpenCode fixtures
        for oc_project in &self.opencode_projects {
            oc_project.build(&opencode_storage, &workspace_root);
        }

        // Build Claude fixtures
        for cl_project in &self.claude_projects {
            cl_project.build(&claude_projects, &workspace_root);
        }

        // CLI arguments
        for arg in &self.args {
            match arg {
                CmdArg::Raw(value) => {
                    cmd.arg(value);
                }
                CmdArg::Path(value) => {
                    let mapped = map_path(value, &workspace_root);
                    std::fs::create_dir_all(&mapped).expect("Create arg path dir");
                    cmd.arg(mapped);
                }
            }
        }

        CmdThen {
            cmd,
            _temp_dir: self.temp_dir,
            stdout: None,
            stderr: None,
            exit_code: None,
        }
    }
}

/// Execution phase - command has run, ready for assertions.
pub struct CmdThen {
    cmd: std::process::Command,
    _temp_dir: TempDir,
    stdout: Option<String>,
    stderr: Option<String>,
    exit_code: Option<i32>,
}

impl CmdThen {
    /// Execute the command.
    fn run(&mut self) {
        let output = self.cmd.output().expect("Failed to execute command");
        self.stdout = Some(String::from_utf8_lossy(&output.stdout).to_string());
        self.stderr = Some(String::from_utf8_lossy(&output.stderr).to_string());
        self.exit_code = Some(output.status.code().unwrap_or(-1));
    }

    /// Assert the command succeeded (exit code 0).
    pub fn should_succeed(&mut self) -> &mut Self {
        self.run();
        assert!(
            self.exit_code.unwrap() == 0,
            "Expected success but got exit code {}\nStderr: {}",
            self.exit_code.unwrap(),
            self.stderr.as_ref().unwrap_or(&String::new())
        );
        self
    }

    /// Assert the command failed (non-zero exit code).
    pub fn should_fail(&mut self) -> &mut Self {
        self.run();
        assert!(
            self.exit_code.unwrap() != 0,
            "Expected failure but succeeded"
        );
        self
    }

    /// Assert stderr contains expected text.
    pub fn expect_error_contains(&mut self, expected: &str) -> &mut Self {
        let stderr = self.stderr.as_ref().expect("Command not run");
        assert!(
            stderr.contains(expected),
            "Expected stderr to contain '{}'\nStderr: {}",
            expected,
            stderr
        );
        self
    }

    /// Parse stdout as JSON for assertions.
    pub fn expect_stdout_json(&mut self) -> JsonAssert {
        let stdout = self.stdout.as_ref().expect("Command not run").clone();
        let value: Value = serde_json::from_str(&stdout).expect("Failed to parse stdout as JSON");
        JsonAssert { value }
    }

    /// Get reference to stdout for custom assertions.
    pub fn stdout(&self) -> &str {
        self.stdout.as_ref().expect("Command not run")
    }

    /// Get reference to stderr for custom assertions.
    pub fn stderr(&self) -> &str {
        self.stderr.as_ref().expect("Command not run")
    }

    /// Get exit code.
    pub fn exit_code(&self) -> i32 {
        self.exit_code.expect("Command not run")
    }
}

/// JSON assertion helper.
pub struct JsonAssert {
    pub value: Value,
}

impl JsonAssert {
    /// Assert a field at JSON path equals expected value.
    pub fn field_eq(self, path: &str, expected: Value) -> Self {
        let actual = self
            .value
            .pointer(path)
            .expect(&format!("Expected path '{}' to exist in JSON", path));
        assert_eq!(
            actual, &expected,
            "Field '{}' mismatch: expected {}, got {}",
            path, expected, actual
        );
        self
    }

    /// Assert a field at JSON path contains a substring.
    pub fn field_contains(self, path: &str, expected: &str) -> Self {
        let actual = self
            .value
            .pointer(path)
            .expect(&format!("Expected path '{}' to exist in JSON", path));
        let actual_str = actual.as_str().expect("Expected JSON value to be a string");
        assert!(
            actual_str.contains(expected),
            "Field '{}' mismatch: expected to contain '{}', got '{}'",
            path,
            expected,
            actual_str
        );
        self
    }

    /// Validate all assertions and return the underlying value.
    pub fn validate(self) -> Value {
        self.value
    }
}

fn map_path(path: &Path, workspace_root: &Path) -> PathBuf {
    if path.is_absolute() {
        let stripped = path.strip_prefix("/").unwrap_or(path);
        workspace_root.join(stripped)
    } else {
        workspace_root.join(path)
    }
}

// --- Fixture Builders ---

struct OpencodeProjectBuilder {
    worktree_path: String,
    project_id_hint: String,
    sessions: Vec<OpencodeSessionBuilder>,
}

impl OpencodeProjectBuilder {
    fn build(&self, storage_root: &PathBuf, workspace_root: &PathBuf) {
        // Create project file
        let project_id = sha256_hash(&self.worktree_path);
        let project_dir = storage_root.join("project");
        std::fs::create_dir_all(&project_dir).expect("Create project dir");

        let project_file = project_dir.join(&format!("{}.json", project_id));
        let mapped_worktree = map_path(Path::new(&self.worktree_path), workspace_root);
        std::fs::create_dir_all(&mapped_worktree).expect("Create worktree dir");
        let project_json = serde_json::json!({
            "id": project_id,
            "worktree": mapped_worktree.to_string_lossy(),
            "vcs": "git",
            "time": { "created": 1700000000000i64, "updated": 1700000000000i64 },
            "sandboxes": []
        });
        std::fs::write(&project_file, project_json.to_string()).expect("Write project file");

        // Create session directory
        let session_dir = storage_root.join("session").join(&project_id);
        std::fs::create_dir_all(&session_dir).expect("Create session dir");

        // Create sessions
        for (i, session) in self.sessions.iter().enumerate() {
            let session_id = session.session_id.clone();
            let session_file = session_dir.join(&format!("{}.json", session_id));
            let session_json = serde_json::json!({
                "id": session_id,
                "version": "1.0",
                "projectID": project_id,
                "directory": mapped_worktree.to_string_lossy(),
                "title": format!("Test Session {}", i),
                "time": { "created": 1700000000000i64 + (i as i64 * 3600000), "updated": 1700000000000i64 + (i as i64 * 3600000) }
            });
            std::fs::write(&session_file, session_json.to_string()).expect("Write session file");

            // Create messages
            let message_dir = storage_root.join("message").join(&session_id);
            std::fs::create_dir_all(&message_dir).expect("Create message dir");

            for (j, msg) in session.messages.iter().enumerate() {
                let msg_id = format!("msg_{:x}", j);
                let msg_file = message_dir.join(&format!("{}.json", msg_id));
                let created_ms = msg.created_ms;
                let msg_json = serde_json::json!({
                    "id": msg_id,
                    "sessionID": session_id,
                    "role": msg.role,
                    "time": { "created": created_ms },
                    "modelID": msg.model_id,
                    "providerID": msg.provider_id,
                    "tokens": {
                        "input": msg.input_tokens,
                        "output": msg.output_tokens,
                        "reasoning": 0,
                        "cache": { "read": 0, "write": 0 }
                    }
                });
                std::fs::write(&msg_file, msg_json.to_string()).expect("Write message file");
            }
        }
    }
}

struct OpencodeSessionBuilder {
    session_id: String,
    messages: Vec<OpencodeMessageBuilder>,
}

struct OpencodeMessageBuilder {
    role: String,
    provider_id: String,
    model_id: String,
    input_tokens: u64,
    output_tokens: u64,
    created_ms: i64,
}

struct ClaudeProjectBuilder {
    project_path: PathBuf,
    sessions: Vec<ClaudeSessionBuilder>,
}

impl ClaudeProjectBuilder {
    fn build(&self, projects_root: &PathBuf, workspace_root: &PathBuf) {
        let mapped_project = map_path(&self.project_path, workspace_root);
        std::fs::create_dir_all(&mapped_project).expect("Create mapped claude project");
        let encoded_name = url_encode(&mapped_project.to_string_lossy());
        let project_dir = projects_root.join(&encoded_name);
        std::fs::create_dir_all(&project_dir).expect("Create claude project dir");

        let index_file = project_dir.join("sessions-index.json");
        let index_json = serde_json::json!({
            "entries": [
                {
                    "projectPath": mapped_project.to_string_lossy(),
                    "sessionId": "session-index"
                }
            ]
        });
        std::fs::write(&index_file, index_json.to_string()).expect("Write sessions index");

        for session in &self.sessions {
            let session_file = project_dir.join(&format!("{}.jsonl", session.session_id));
            let mut lines = Vec::new();

            // Add session entries
            for (i, msg) in session.messages.iter().enumerate() {
                let timestamp = msg.timestamp.clone();
                let parent_uuid: serde_json::Value = if i == 0 {
                    serde_json::Value::Null
                } else {
                    serde_json::json!(format!("uuid-{:x}", i - 1))
                };
                let entry = serde_json::json!({
                    "parentUuid": parent_uuid,
                    "isSidechain": false,
                    "userType": "external",
                    "cwd": mapped_project.to_string_lossy(),
                    "sessionId": session.session_id,
                    "version": "2.0",
                    "gitBranch": "HEAD",
                    "type": "user",
                    "message": {
                        "role": msg.role,
                        "model": msg.model,
                        "content": format!("Message {}", i),
                        "usage": if msg.role == "assistant" {
                            serde_json::json!({
                                "input_tokens": msg.input_tokens,
                                "output_tokens": msg.output_tokens,
                                "cache_creation_input_tokens": 0,
                                "cache_read_input_tokens": 0,
                                "service_tier": "standard"
                            })
                        } else {
                            serde_json::json!(null)
                        }
                    },
                    "uuid": format!("uuid-{:x}", i),
                    "timestamp": timestamp
                });
                lines.push(entry.to_string());
            }

            std::fs::write(&session_file, lines.join("\n")).expect("Write session file");
        }
    }
}

struct ClaudeSessionBuilder {
    session_id: String,
    messages: Vec<ClaudeMessageBuilder>,
}

struct ClaudeMessageBuilder {
    role: String,
    model: String,
    input_tokens: u64,
    output_tokens: u64,
    timestamp: String,
}

// --- Utilities ---

fn sha256_hash(s: &str) -> String {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};

    let mut hasher = DefaultHasher::new();
    s.hash(&mut hasher);
    format!("{:064x}", hasher.finish())
}

fn url_encode(s: &str) -> String {
    let trimmed = s.trim_start_matches('/');
    format!("-{}", trimmed.replace('/', "-"))
}
