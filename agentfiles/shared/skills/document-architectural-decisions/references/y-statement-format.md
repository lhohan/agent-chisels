# Y-Statement Architecture Decision Records

## Overview

Y-Statements capture decision context, addressed requirements, decision outcome, and consequences in a single, structured sentence. The six sections form a "Y" shape, which explains the name.

Originally suggested in a SATURN 2012 presentation by Olaf Zimmermann, building on decision outcome concepts from George Fairbanks' Architecture Haikus.

## Six-Part Structure

### 1. Context
**Question**: In the context of [what component/situation]...
**Purpose**: Describes the functional requirement, use case, or architectural component affected by this decision
**Example**: "In the context of hosting multiple static sites on Hetzner"

### 2. Facing
**Question**: ...facing [what requirement/constraint/problem]...
**Purpose**: Identifies the non-functional requirement or desired quality attribute that prompted the decision
**Example**: "facing the need for simplicity and efficient resource use"

### 3. We Decided
**Question**: **...we decided [what option]...**
**Purpose**: States the chosen option explicitly (should be bolded in tables)
**Example**: **"we decided to serve static sites directly with Nginx or Caddy"**

### 4. And Neglected (Optional)
**Question**: ...and neglected [alternatives]...
**Purpose**: Documents what was NOT chosen and briefly why
**Example**: "(reserving Docker for dynamic apps)"
**Note**: This is optional but recommended for clarity

### 5. To Achieve
**Question**: ...to achieve [goals/requirements]...
**Purpose**: Identifies the benefits and satisfaction of requirements
**Example**: "to achieve streamlined management and minimized overhead"

### 6. Accepting That
**Question**: ...accepting that [trade-offs/consequences]...
**Purpose**: Explicitly acknowledges costs, limitations, or risks of the decision
**Example**: "accepting that..."
**Pattern**: Usually pairs with "to achieve" to show the balance

## Complete Y-Statement Example

```
In the context of provisioning a Hetzner VPS for multiple static sites,
facing the need for a minimal, performant, low-attack-surface OS with strong Ansible support,
we decided to use Debian 13 (Trixie) minimal as the base image with unattended-upgrades for security patches,
to achieve a lean baseline, long-term stability, first-class support, and straightforward hardening and automation.
```

## Format Specification

Y-Statements are organized with a heading for each decision, followed by the statement in a blockquote:

**Format**:
```markdown
### PREFIX-NNN: [Brief description] [Status: Proposed/Accepted/Deprecated/Implemented/Superseded]

> **In the context of** [context],
> **facing** [requirement/constraint],
> **we decided** [choice],
> **to achieve** [benefits],
> **accepting** [trade-offs].
```

**Example**:
```markdown
### WEB-003: GoAccess for self-hosted analytics [Yes]

> **In the context of** using Caddy on a Hetzner VPS,
> **facing** the need for simple, reproducible, self-hosted analytics without client-side tracking,
> **we decided** to use GoAccess,
> **to achieve** real-time, log-based analytics with minimal setup and on-premises data,
> **accepting** less detailed user behavior insights.
```

## ID Prefix Conventions

Use a 3-letter prefix followed by a hyphen and 3-digit counter:

**Pattern**: `PREFIX-NNN` (e.g., `WEB-001`, `API-042`, `DB-015`)

**Conventions**:
- Choose a prefix that represents the domain or area (WEB, API, DB, INFRA, AUTH, etc.)
- Use consistent prefix throughout a single decision log
- Zero-pad the counter to 3 digits (001, not 1)
- Auto-increment for each new decision

**Examples**:
- `WEB-001`: First web infrastructure decision
- `WEB-042`: Forty-second web infrastructure decision
- `API-001`: First API design decision
- `INFRA-015`: Fifteenth infrastructure decision

## Creating Y-Statement Decisions: Step-by-Step Workflow

When helping users add decisions to a Y-statement log:

1. **Read the existing log** to understand the ID prefix pattern and existing decisions
2. **Determine next ID** by finding the highest counter in the log (e.g., if WEB-033 is highest, next is WEB-034)
3. **Gather Y-statement components** through dialogue:
   - **Context**: What component, system, or situation does this affect?
   - **Facing**: What non-functional requirement or constraint prompted this?
   - **Decision**: What was chosen? (Will be bolded in the table)
   - **Alternatives**: [Optional] What was rejected and briefly why?
   - **Benefits** (to achieve): What goals or requirements does this satisfy?
   - **Trade-offs** (accepting): What costs, limitations, or risks are we accepting?
   - **Implementation status**: Yes/No/Partial?
4. **Format the new decision** maintaining consistency with existing format
5. **Insert at top of log** (after the header and introductory text) to maintain reverse chronological order with newest decisions first
6. **Verify readability** - the statement should be understandable even if it's one long sentence; consider splitting into 2-3 sentences if readers prefer

### Initializing a New Y-Statement Log

If no decision records exist, help user:
1. Choose an ID prefix representing their domain (e.g., WEB, API, INFRA, ARCH)
2. Create `decision-log.md` in project root or docs/ directory
3. Use the Y-statement template from assets with customized prefix
4. Add the first decision using the workflow above

## Reviewing Y-Statement Decisions

When reviewing Y-statements, check:
- Are all six components present? (context, facing, decision, to achieve, accepting)
- Is the decision bolded for visibility?
- Are ID numbers consistent with the prefix pattern (no gaps, proper increments)?
- Is the statement understandable? (Suggest splitting long ones into 2-3 sentences if needed)
- Are trade-offs explicit and clear?
- Does the row maintain table formatting?

## Tips for Writing Effective Y-Statements

### Completeness
✓ Include all six parts (context, facing, decision, to achieve, accepting, alternatives optional)
✓ Ensure the decision stands out (bold it)
✓ Make trade-offs explicit in the "accepting that" section

### Clarity
✓ Some readers don't appreciate very long sentences—consider splitting into 2-3 sentences if needed
✓ Avoid jargon without explanation
✓ Use specific language, not vague terms

### Context
✓ Include enough context that someone unfamiliar with the project understands the decision
✓ Explain constraints and limitations that influenced the choice
✓ Reference non-functional requirements explicitly

### Rationale Extension
✓ If rationale doesn't fit the standard "to achieve..., accepting..." format, add a "because" clause
✓ Example: "...because team expertise in TypeScript allows faster implementation and safer refactoring."

## When to Use Y-Statements

**Best suited for**:
- Lightweight decision logging
- Tactical choices (tool selection, process decisions)
- Organizations that prefer minimal ceremony
- Projects that make many decisions and need to track them efficiently
- Real-time decision capture in sprints or standups

**Less suited for**:
- Major architectural decisions requiring deep rationale
- Decisions with complex alternatives that need detailed comparison
- Situations requiring extensive verification criteria
- Teams preferring comprehensive historical records

## Evaluation Criteria

A well-written Y-statement:
- ✓ Is understandable to someone unfamiliar with the project
- ✓ Clearly states what was decided
- ✓ Explains the context that prompted the decision
- ✓ Identifies trade-offs explicitly
- ✓ Is specific enough to be useful months or years later
- ✓ Has all six parts (or clearly omits optional alternatives)
- ✓ Uses consistent language and formatting within the log

## External Resources

- [DPR Architecture Decision Record Y-Statement Template](https://socadk.github.io/design-practice-repository/artifact-templates/DPR-ArchitecturalDecisionRecordYForm.html)
- [Architecture Decision Records GitHub Organization](https://adr.github.io/)
- [Architectural Knowledge Management at OST/IFS](https://www.ost.ch/de/forschung-und-dienstleistungen/informatik/ifs-institut-fuer-software)
