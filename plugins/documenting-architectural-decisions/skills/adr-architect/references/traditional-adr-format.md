# Traditional Architecture Decision Records (ADRs)

## Overview

Traditional ADRs are individual markdown files, each documenting a single significant architectural decision. Each file follows a consistent structure with detailed sections covering context, rationale, consequences, and verification criteria.

This format is well-established, with detailed examples available from authors like Michael Nygard and projects like the ADR GitHub organization.

## Recommended Structure

### 1. Title
Clear, specific decision statement in the filename and header.

**Format**: `adr/NNN-hyphenated-title.md` or `adr/NNN_hyphenated_title.md`

**Examples**:
- `adr/001-move-api-from-rest-to-graphql.md`
- `adr/002-adopt-postgresql-for-sessions.md`
- `adr/015-use-kubernetes-for-orchestration.md`

### 2. Status
Current state of the decision. Used to track whether decisions are still active, replaced, or deprecated.

**Valid values**:
- **Proposed**: Under consideration, not yet accepted
- **Accepted**: Agreed upon and being implemented
- **Deprecated**: No longer relevant, superseded
- **Superseded**: Replaced by another ADR (reference the new one)

**Example**:
```markdown
## Status
Accepted
```

### 3. Context
The situation that necessitated this decision. Includes business drivers, technical constraints, and organizational factors.

**Key elements**:
- What problem or opportunity prompted this decision?
- What constraints or limitations influenced it?
- What alternatives were considered?
- What is the current state?

**Example**:
```markdown
## Context

The project needed to move away from REST APIs because of limitations in expressing complex relationships
and the overhead of multiple round-trips to satisfy client data requirements. The team has limited experience
with GraphQL but strong expertise in Node.js and JavaScript tooling.
```

### 4. Decision
What was decided and key implementation details. Be specific and concrete.

**Key elements**:
- What option was chosen?
- How will it be implemented?
- What are the key technical details?
- Who will be responsible?

**Example**:
```markdown
## Decision

We will adopt Apollo Server as our GraphQL server implementation, migrating from our Express-based REST API
incrementally. The migration will proceed endpoint-by-endpoint, maintaining REST compatibility during transition.
```

### 5. Rationale
Why this decision was made. The reasoning behind choosing this option over alternatives.

**Key elements**:
- Why is this the best choice?
- What makes it superior to alternatives?
- What trade-offs were accepted?
- What constraints influenced the decision?
- What assumptions are we making?

**Example**:
```markdown
## Rationale

Apollo Server was chosen for several reasons:

**Advantages over alternatives**:
- Strong ecosystem with battle-tested tooling
- Excellent documentation and community support
- Built-in federation support for future microservices
- Good performance characteristics

**Trade-offs accepted**:
- Learning curve for team unfamiliar with GraphQL
- Need to rewrite client-server contract
- Potential performance overhead if not optimized
- New operational complexity in monitoring

**Constraints**:
- Must maintain REST compatibility during migration
- Cannot do complete rewrite due to production constraints
- Need to keep existing authentication patterns
```

### 6. Consequences
Expected outcomes, both positive and negative. What does this decision enable and what does it constrain?

**Key elements**:
- What becomes possible?
- What becomes harder or impossible?
- What are the short-term effects?
- What are the long-term implications?
- Are there second-order effects?

**Example**:
```markdown
## Consequences

**Positive**:
- Reduced number of API calls and data over-fetching
- Better type safety with schema validation
- Easier client-side state management (Apollo Client)
- Foundation for future microservices federation

**Negative**:
- Learning curve for REST-focused team
- GraphQL query complexity requires careful monitoring
- Increased initial implementation time
- New security considerations (depth limiting, query complexity analysis)

**Long-term implications**:
- Foundation for scaling to microservices
- Possible performance challenges if queries not optimized
- Easier to add new clients (mobile, third-party)
```

### 7. Verification
How will we know this decision is working? Grounding the decision in reality through measurable criteria.

**Key elements**:
- Self-assessment questions (e.g., "Is X in place?")
- Metrics to track (e.g., "Deployment frequency > daily")
- Automated checks or fitness functions
- Who is responsible for verification

**Example**:
```markdown
## Verification

- Is the session store using PostgreSQL? (Check connection string)
- Session latency: <10ms p95 under normal load
- Database CPU impact: <5% increase at peak
- Review at 3 months: Is this still the right choice?
```

## Complete ADR Example

```markdown
# ADR 001: Adopt PostgreSQL for Session State

## Status
Accepted

## Context
The session management system currently relies on in-memory state in Redis,
which limits our ability to scale horizontally. Database sessions require
persistence across application instances and server restarts.

## Decision
We will adopt PostgreSQL as our persistent session store, replacing the
current Redis implementation with a database-backed solution using the
connect-pg-simple middleware for Express.js.

## Rationale
PostgreSQL was chosen because:
- We already operate a PostgreSQL cluster for application data
- Reduces operational overhead (one less system to manage)
- Better for long-term session retention and auditing
- Good performance for our session query patterns

Trade-offs:
- Slight latency increase compared to Redis (acceptable for our use case)
- Need to implement session table indexing and cleanup jobs
- Additional database load during peak traffic

## Consequences
- Simplified operational stack (no separate Redis requirement)
- Ability to audit session history
- Better session persistence and reliability
- Modest performance trade-off (acceptable)

## Verification
- Session operations: <10ms p95 latency
- Database CPU impact: <5% increase under peak load
- Session persistence: 100% of sessions survive application restart
- Evaluation at 3 months and 6 months
```

## Creating Traditional ADRs: Step-by-Step Workflow

When helping users create traditional ADRs:

1. **Read existing ADRs** to understand numbering scheme (001, 002, 003, etc.) and patterns
2. **Determine next number** by finding the highest number and incrementing
3. **Probe for decision context** through clarifying questions:
   - What situation necessitated this decision?
   - What constraints or limitations influenced the choice?
   - What alternatives were considered?
   - What trade-offs are being accepted?
4. **Extract implicit knowledge** - help users articulate assumptions and reasoning they might take for granted
5. **Gather ADR components**:
   - **Filename**: `NNN-hyphenated-title.md` (e.g., `001-adopt-postgresql-for-sessions.md`)
   - **Status**: Proposed/Accepted/Deprecated/Superseded
   - **Context**: Situation necessitating this decision (business drivers, constraints, current state)
   - **Decision**: What was decided and key implementation details
   - **Rationale**: Why this option (advantages, alternatives rejected, trade-offs, constraints, assumptions)
   - **Consequences**: Both positive and negative outcomes, long-term implications
   - **Verification**: Observable metrics, timeframes, early warning signs
6. **Create file** in `adr/` directory with all sections completed
7. **Link to related ADRs** if applicable
8. **Focus on future utility** - write so someone reading it months/years later will understand the reasoning

### Initializing a New Traditional ADR Directory

If no decision records exist, help user:
1. Create `adr/` directory in project root
2. Create first file `adr/001-decision-title.md`
3. Use the traditional ADR template from assets
4. Complete all sections with comprehensive detail
5. Follow quality criteria for each section

## Reviewing Traditional ADRs

When reviewing traditional ADRs, check:
- Are all sections present and complete?
- Does **Context** explain situation, constraints, and business drivers?
- Does **Decision** provide clear implementation details?
- Does **Rationale** explain "why," not just "what"? Does it compare alternatives?
- Are **Consequences** both positive AND negative? Do they include long-term implications?
- Is **Verification** grounded in reality with pragmatic, measurable criteria?
- Are related decisions linked in the decision record?
- Is language clear, professional, and jargon-free?

**Improvement suggestions**:
- Add missing context or constraints
- Clarify vague language or jargon
- Strengthen verification criteria with measurable metrics
- Identify and link related decisions
- Ensure trade-offs are explicit

## ADR Best Practices

### Conciseness with Completeness
✓ Every section serves a purpose
✓ Remove unnecessary details but keep crucial context
✓ Use precise language
✓ Avoid marketing language or excessive enthusiasm

### Future Utility
✓ Write for a reader 6-12 months in the future (possibly yourself)
✓ Explain the "why," not just the "what"
✓ Include constraints and assumptions that influenced the decision
✓ Link to related decisions and context

### Verification Focus
✓ Ground decisions in reality through measurable criteria
✓ Keep verification pragmatic—match the approach to the decision's scope
✓ Include self-assessment questions, metrics, or automated checks as appropriate
✓ Specify who is responsible for verification

### Clarity and Consistency
✓ Use consistent formatting across all ADRs
✓ Use clear section headings
✓ Avoid jargon or explain unfamiliar terms
✓ Use links to reference related ADRs, requirements, or documentation

## When to Write a Traditional ADR

**Best suited for**:
- Major architectural decisions with long-term impact
- Decisions affecting multiple teams or systems
- Complex trade-offs requiring detailed explanation
- Decisions that benefit from comprehensive historical record
- Organizations that value ceremony and detailed documentation

**Consider writing an ADR if**:
- The decision affects application architecture or system design
- There are multiple viable alternatives with different trade-offs
- The decision will influence future technical choices
- Future team members will benefit from understanding the reasoning
- The decision has cost, performance, or organizational implications

## External Resources

- [Michael Nygard's Original ADR Format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [Architecture Decision Records GitHub Organization](https://adr.github.io/)
- [Markdown Architecture Decision Records (MADR) Template](https://github.com/adr/madr)
- [Architecture Decision Records: Full Template](https://github.com/joelparkerhenderson/architecture-decision-record)
