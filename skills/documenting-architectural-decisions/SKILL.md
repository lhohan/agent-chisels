---
name: documenting-architectural-decisions
description: Document and manage architectural decisions using ADRs. Supports Y-statement and traditional ADR formats. Use when creating, reviewing, or searching decision records.
version: 0.2.0
---

# Architecture Decision Records (ADRs) Framework

You are an expert architecture consultant specializing in creating exceptional Architecture Decision Records (ADRs). Your expertise lies in transforming complex architectural decisions into clear, actionable documentation that serves as a reliable reference for future decision-making.

## Table of Contents

- [Format Auto-Detection](#format-auto-detection)
- [Resources](#resources)
- [ADR Purposes and Benefits](#adr-purposes-and-benefits)
- [Choosing Between Formats](#choosing-between-formats)
- [Quality Criteria for Both Formats](#quality-criteria-for-both-formats)
- [Superseding Decisions](#superseding-decisions)
- [Searching Past Decisions](#searching-past-decisions)
- [External Resources](#external-resources)

## Format Auto-Detection

On first use, automatically detect your project's ADR format:

1. **Traditional ADRs**: Look for `adr/*.md` or `docs/adr/*.md`
2. **Y-Statements**: Look for `*decision-log.md` or `ADR.md`
3. **No records**: Ask which format to initialize

Format is a repository-level convention—once chosen, all decisions follow the same pattern.

## Resources

The skill includes detailed references:

- **`references/y-statement-format.md`**: Read for Y-statement specification, ID conventions, structure
- **`references/traditional-adr-format.md`**: Read for traditional ADR sections, best practices
- **`examples/y-statement-examples.md`**: Read for real Y-statement examples
- **`examples/traditional-adr-example.md`**: Read for traditional ADR example
- **`assets/y-statement-template.md`**: Use when initializing new Y-statement log
- **`assets/traditional-adr-template.md`**: Use when initializing new traditional ADR

Consult these resources as needed when creating or reviewing decisions.

## ADR Purposes and Benefits

ADRs document important architectural choices, including:
- Technology selections and alternatives considered
- Design patterns and architectural patterns
- System boundaries and integration approaches
- Significant trade-off decisions
- Process and organizational choices

ADRs serve as a reliable reference for understanding past decisions and their reasoning.

## Choosing Between Formats

### Traditional ADRs (Multi-file)
**Best for**: Architectural decisions requiring comprehensive documentation

**When to use**:
- Major architectural decisions with long-term impact
- Decisions affecting multiple teams or systems
- Complex trade-offs requiring detailed explanation

**Structure overview**: Individual files with Title, Status, Context, Decision, Rationale, Consequences, Verification sections.

**See**: `references/traditional-adr-format.md` for complete specification and workflows

### Y-Statements (Single File Log)
**Best for**: Lightweight decision logging and tactical choices

**When to use**:
- Rapid decision capture
- Tactical choices (tool selection, process decisions)
- Organizations preferring minimal ceremony

**Structure overview**: Six-part Y-statement pattern (context, facing, decision, to achieve, accepting, alternatives).

**See**: `references/y-statement-format.md` for complete specification and workflows

## Quality Criteria for Both Formats

Good ADRs:
- Capture the business/technical context clearly
- Explain the reasoning, not just the decision
- Acknowledge trade-offs explicitly
- Include concrete verification criteria
- Are written for a future reader (including the author)
- Use consistent, professional language
- Link to related decisions when applicable

## Superseding Decisions

When a new decision replaces an existing one:

1. **Update the old ADR's status** to `Superseded by ADR-NNN` (or update the Y-Statement row)
2. **Add a link in the old ADR** pointing to the new decision
3. **Add a link in the new ADR** referencing what it supersedes

**Example in old ADR**:
```markdown
## Status
Superseded by [ADR-015](./015-use-redis-for-sessions.md)
```

**Example in new ADR**:
```markdown
## Related Decisions
- Supersedes [ADR-001](./001-adopt-postgresql-for-sessions.md): PostgreSQL session store replaced due to latency requirements
```

**For Y-Statements**: Update the old row's status to "Superseded" and add a note referencing the new decision ID.

## Searching Past Decisions

When users need to find past decisions:

### For Y-Statement logs (single file):
- Search by keyword in `decision-log.md`
- Filter by ID prefix (e.g., all WEB-* decisions)
- Look for similar patterns in existing decisions to understand conventions
- Check Implementation column to find active vs. completed decisions

### For Traditional ADRs (multiple files):
- Search by filename and title
- Review file numbers to find decisions in a range
- Look in Rationale sections for comparisons and alternatives discussed
- Check "Status" fields to find still-relevant (Accepted) vs. superseded decisions
- Follow related decision links to understand decision chains

**Questions to prompt**:
- Has this decision been made before in the project?
- Are there related decisions I should review?
- What's the current status of this decision (Proposed/Accepted/Superseded)?
- What alternatives were considered and rejected (and why)?

## External Resources

- [Y-Statements Template](https://socadk.github.io/design-practice-repository/artifact-templates/DPR-ArchitecturalDecisionRecordYForm.html)
- [ADR GitHub Organization](https://adr.github.io/)
- [Markdown ADR Template](https://github.com/adr/madr)
- [Architecture Haikus](https://www.georgefairbanks.com/blog/comparch-wicsa-2011-panel-discussion-and-haiku-tutorial/)
