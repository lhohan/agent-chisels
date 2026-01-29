# Traditional ADR Example

## ADR-01: Share Commands Between Claude and Opencode

```markdown
# ADR 001: Share Commands Between Claude Code and Opencode via Symlinks

## Status
Accepted

## Context

Both Claude Code and Opencode are used in this project, and they need access to the same custom commands
for consistency and maintainability. Currently, commands could be duplicated across both tools, leading to
maintenance burden and inconsistency.

Both tools support markdown-based commands with identical frontmatter format (description, argument-hint).
The format is fully compatible between tools.

## Decision

Commands will be stored in a canonical location at `.claude/commands/` and symlinked from Opencode's
command directory (`.config/opencode/command/` → `.claude/commands/`).

This creates a single source of truth for all commands while maintaining compatibility with both tools.

## Rationale

**Advantages**:
- Single source of truth eliminates synchronization burden
- Markdown format is identical in both tools—no translation needed
- Symlinks are well-supported on all platforms (Linux, macOS, Windows with Git Bash)
- Reduces cognitive load—developers maintain one command list
- Easy to discover: all commands in one location

**Alternatives considered**:
- Duplicate commands in both locations: Rejected due to maintenance burden
- Store in Opencode only: Rejected because Claude Code is primary tool
- Custom sync script: Unnecessary given symlink reliability

**Trade-offs**:
- Requires symlink setup (one-time)
- Anyone cloning the repo needs to understand the symlink relationship
- Minimal additional complexity

**Why this approach**:
Commands are truly tool-agnostic documentation—they're just markdown files describing what Claude should do.
The format is identical in both tools, so a symlink is the simplest, most maintainable approach.

## Consequences

**Positive**:
- Reduced maintenance overhead (single source of truth)
- Easier to add new commands (one location)
- Consistency across tools
- Clear command organization

**Negative**:
- Team members need to understand symlinks
- Symlinks may need special handling in some workflows
- Troubleshooting symlink issues requires understanding filesystem links

**Operational**:
- Commands are instantly available in both tools
- Changes to commands immediately affect both tools
- No synchronization lag or drift

## Verification

- Verify symlink exists: `ls -la ~/.config/opencode/command/`
- Verify commands are accessible in both Claude Code and Opencode CLI
- Test that editing a command in `.claude/commands/` reflects in Opencode
- Test that new commands added to `.claude/commands/` are available in both tools

Success: All commands available in both tools with single source of truth
Evaluation: Ongoing—if symlinks cause issues, revisit alternative approaches
```

## Key Features of This ADR

- **Clear motivation and context**: Explains the problem (duplication, inconsistency)
- **Explains what makes this solution work**: Format compatibility between tools
- **Acknowledges trade-offs explicitly**: Setup requirement, symlink understanding
- **Provides specific verification steps**: Concrete commands to verify success
- **Written for future readers**: Explains reasoning, not just decision

## Y-Statements vs. Traditional ADRs

**Y-Statements are better for**:
- Quick decision logging
- Tactical decisions about tools, configurations, processes
- Organizations that want minimal ceremony
- Maintaining a searchable log of many decisions
- Decisions where trade-offs are clear and simple

**Traditional ADRs are better for**:
- Major architectural decisions
- Decisions with complex alternatives
- Situations requiring detailed historical record
- Decisions affecting multiple teams
- Cases where explaining the reasoning is crucial

## Structure Comparison

| Aspect | Y-Statement | Traditional ADR |
|--------|-------------|-----------------|
| Length | One sentence (or split into 2-3) | Multiple sections, 500-1000 words |
| Alternatives | Optional mention | Detailed comparison section |
| Verification | Implicit in "to achieve" | Explicit, measurable criteria section |
| Trade-offs | Clear in "accepting" clause | Detailed in Consequences section |
| File organization | Single decision log table | Individual files per decision |
| Ceremony level | Low | High |
| Best for | Tactical, lightweight decisions | Strategic, major decisions |
