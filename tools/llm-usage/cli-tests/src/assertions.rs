//! Domain-specific assertions for llm-usage output.
//!
//! These assertions provide a fluent API for checking OpenCode and Claude Code
//! specific metrics in the output JSON.

use serde_json::Value;

use crate::dsl::JsonAssert;

/// Domain assertions for OpenCode metrics.
pub struct OpencodeAssert<'a> {
    parent: &'a JsonAssert,
    opencode: Value,
}

impl<'a> OpencodeAssert<'a> {
    /// Assert total session count.
    pub fn sessions(self, expected: u64) -> Self {
        let actual = self
            .opencode
            .get("sessions")
            .expect("Expected 'sessions' field in opencode");
        assert_eq!(
            actual.as_u64().unwrap(),
            expected,
            "OpenCode sessions: expected {}, got {}",
            expected,
            actual
        );
        self
    }

    /// Assert session count for a specific model.
    pub fn sessions_by_model(self, model: &str, expected: u64) -> Self {
        let sbm = self
            .opencode
            .get("sessions_by_model")
            .expect("Expected 'sessions_by_model' field");
        let actual = sbm
            .get(model)
            .expect(&format!("Expected model '{}' in sessions_by_model", model));
        assert_eq!(
            actual.as_u64().unwrap(),
            expected,
            "OpenCode sessions_by_model[{}]: expected {}, got {}",
            model,
            expected,
            actual
        );
        self
    }

    /// Assert total message count.
    pub fn messages(self, expected: u64) -> Self {
        let actual = self
            .opencode
            .get("messages")
            .expect("Expected 'messages' field in opencode");
        assert_eq!(
            actual.as_u64().unwrap(),
            expected,
            "OpenCode messages: expected {}, got {}",
            expected,
            actual
        );
        self
    }

    /// Assert message count for a specific model.
    pub fn messages_by_model(self, model: &str, expected: u64) -> Self {
        let mbm = self
            .opencode
            .get("messages_by_model")
            .expect("Expected 'messages_by_model' field");
        let actual = mbm
            .get(model)
            .expect(&format!("Expected model '{}' in messages_by_model", model));
        assert_eq!(
            actual.as_u64().unwrap(),
            expected,
            "OpenCode messages_by_model[{}]: expected {}, got {}",
            model,
            expected,
            actual
        );
        self
    }

    /// Assert token count for a specific model.
    pub fn tokens(self, model: &str, input: u64, output: u64) -> Self {
        let tokens = self
            .opencode
            .get("tokens")
            .expect("Expected 'tokens' field in opencode");
        let model_tokens = tokens
            .get(model)
            .expect(&format!("Expected model '{}' in tokens", model));
        let actual_input = model_tokens
            .get("input")
            .expect(&format!("Expected 'input' for model '{}'", model));
        let actual_output = model_tokens
            .get("output")
            .expect(&format!("Expected 'output' for model '{}'", model));

        assert_eq!(
            actual_input.as_u64().unwrap(),
            input,
            "OpenCode tokens[{}].input: expected {}, got {}",
            model,
            input,
            actual_input
        );
        assert_eq!(
            actual_output.as_u64().unwrap(),
            output,
            "OpenCode tokens[{}].output: expected {}, got {}",
            model,
            output,
            actual_output
        );
        self
    }

    /// Assert found flag.
    pub fn found(self, expected: bool) -> Self {
        let actual = self
            .opencode
            .get("found")
            .expect("Expected 'found' field in opencode");
        assert_eq!(
            actual.as_bool().unwrap(),
            expected,
            "OpenCode found: expected {}, got {}",
            expected,
            actual
        );
        self
    }

    /// Validate and return parent assertions.
    pub fn validate(self) -> &'a JsonAssert {
        self.parent
    }
}

/// Domain assertions for Claude Code metrics.
pub struct ClaudeAssert<'a> {
    parent: &'a JsonAssert,
    claude: Value,
}

impl<'a> ClaudeAssert<'a> {
    /// Assert total session count.
    pub fn sessions(self, expected: u64) -> Self {
        let actual = self
            .claude
            .get("sessions")
            .expect("Expected 'sessions' field in claude_code");
        assert_eq!(
            actual.as_u64().unwrap(),
            expected,
            "Claude sessions: expected {}, got {}",
            expected,
            actual
        );
        self
    }

    /// Assert session count for a specific model.
    pub fn sessions_by_model(self, model: &str, expected: u64) -> Self {
        let sbm = self
            .claude
            .get("sessions_by_model")
            .expect("Expected 'sessions_by_model' field");
        let actual = sbm
            .get(model)
            .expect(&format!("Expected model '{}' in sessions_by_model", model));
        assert_eq!(
            actual.as_u64().unwrap(),
            expected,
            "Claude sessions_by_model[{}]: expected {}, got {}",
            model,
            expected,
            actual
        );
        self
    }

    /// Assert total message count.
    pub fn messages(self, expected: u64) -> Self {
        let actual = self
            .claude
            .get("messages")
            .expect("Expected 'messages' field in claude_code");
        assert_eq!(
            actual.as_u64().unwrap(),
            expected,
            "Claude messages: expected {}, got {}",
            expected,
            actual
        );
        self
    }

    /// Assert token count for a specific model.
    pub fn tokens(self, model: &str, input: u64, output: u64) -> Self {
        let tokens = self
            .claude
            .get("tokens")
            .expect("Expected 'tokens' field in claude_code");
        let model_tokens = tokens
            .get(model)
            .expect(&format!("Expected model '{}' in tokens", model));
        let actual_input = model_tokens
            .get("input")
            .expect(&format!("Expected 'input' for model '{}'", model));
        let actual_output = model_tokens
            .get("output")
            .expect(&format!("Expected 'output' for model '{}'", model));

        assert_eq!(
            actual_input.as_u64().unwrap(),
            input,
            "Claude tokens[{}].input: expected {}, got {}",
            model,
            input,
            actual_input
        );
        assert_eq!(
            actual_output.as_u64().unwrap(),
            output,
            "Claude tokens[{}].output: expected {}, got {}",
            model,
            output,
            actual_output
        );
        self
    }

    /// Assert found flag.
    pub fn found(self, expected: bool) -> Self {
        let actual = self
            .claude
            .get("found")
            .expect("Expected 'found' field in claude_code");
        assert_eq!(
            actual.as_bool().unwrap(),
            expected,
            "Claude found: expected {}, got {}",
            expected,
            actual
        );
        self
    }

    /// Validate and return parent assertions.
    pub fn validate(self) -> &'a JsonAssert {
        self.parent
    }
}

/// Extended JSONAssert with domain-specific methods.
pub trait DomainAssertions {
    /// Get OpenCode assertions.
    fn expect_opencode<F>(self, f: F) -> Self
    where
        F: FnOnce(OpencodeAssert) -> OpencodeAssert;

    /// Get Claude Code assertions.
    fn expect_claude_code<F>(self, f: F) -> Self
    where
        F: FnOnce(ClaudeAssert) -> ClaudeAssert;
}

impl DomainAssertions for JsonAssert {
    fn expect_opencode<F>(self, f: F) -> Self
    where
        F: FnOnce(OpencodeAssert) -> OpencodeAssert,
    {
        let opencode = self
            .value
            .get("opencode")
            .expect("Expected 'opencode' field in output")
            .clone();
        f(OpencodeAssert {
            parent: &self,
            opencode,
        });
        self
    }

    fn expect_claude_code<F>(self, f: F) -> Self
    where
        F: FnOnce(ClaudeAssert) -> ClaudeAssert,
    {
        let claude = self
            .value
            .get("claude_code")
            .expect("Expected 'claude_code' field in output")
            .clone();
        f(ClaudeAssert {
            parent: &self,
            claude,
        });
        self
    }
}
