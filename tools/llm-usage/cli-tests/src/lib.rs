// Re-export DSL components
pub use dsl::{ClaudeMessage, Cmd, CmdGiven, CmdThen, JsonAssert, OpencodeMessage};

// Re-export assertions
pub use assertions::DomainAssertions;

mod assertions;
pub mod dsl;
