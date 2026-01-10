# Decision Log

### JJ-006: Keep Simple SessionStart Hook [Yes]

> **In the context of** improving jj reminder effectiveness in long sessions,
> **facing** options to use UserPromptSubmit hooks with VCS keyword matchers for more persistent reminders,
> **we decided** to keep the current simple SessionStart hook and rely on the `/use-jj` command for manual reinforcement,
> **to achieve** simplicity and avoid overhead of prompt inspection on every VCS-related message,
> **accepting** that long sessions may occasionally need manual `/use-jj` invocation.

See `backlog/jj-userpromptsubmit-hooks.md` for research on UserPromptSubmit alternatives.

### JJ-005: Shared Root-Aware Detection Script [Yes]

> **In the context of** providing reliable Jujutsu (jj) VCS support across diverse repository structures,
> **facing** duplicated detection logic and the risk of "double detection" between the hook and the skills,
> **we decided** to extract the detection logic into a script (`scripts/detect-jj.sh`) as an authoritative check,
> **to achieve** a single source of truth for repository detection, better reliability in root-relative paths, and cleaner separation between the hook (deterministic gating) and the skill (interactive guidance)

### JJ-004: Strengthened Reminder Language [Yes]

> **In the context of** balancing startup speed with VCS reliability,
> **facing** the risk of the model ignoring passive context in long sessions,
> **we decided** to use "strong language" in the hook and `/use-jj` command that explicitly instructs the model to consult the `detecting-jujutsu` or `using-jujutsu` skills *before* executing any command,
> **to achieve** high compliance without the 5-second latency cost of a forced skill-invocation loop at startup,
> **accepting** that the model still maintains a small chance of "forgetting" which is mitigated by the manual `/use-jj` fallback and the top-of-context placement.

### JJ-003: Split Detection vs. Guidance Skills [Yes]

> **In the context of** providing layered support for Jujutsu (jj) in Claude Code,
> **facing** the potential for model confusion when combining detection logic and deep guidance into a single skill,
> **we decided** to split the capability into two distinct skills: `detecting-jujutsu` (for repository verification) and `using-jujutsu` (for detailed guidance),
> **to achieve** a clearer separation of concerns and more precise skill triggering based on the model's current need (verification vs. execution),
> **accepting** the added complexity of managing two skill files within the same plugin.

### JJ-002: Hybrid Hook and Skill Architecture [Yes]

> **In the context of** providing robust Jujutsu (jj) VCS support in Claude Code,
> **facing** the trade-off between deterministic reinforcement (hooks) and detailed semantic guidance (skills),
> **we decided** to use a lightweight SessionStart hook for initial "critical" reminders and a comprehensive `jj` skill (based on `jj-vcs.md`) for deep guidance,
> **to achieve** a balance of guaranteed awareness and on-demand instruction without bloating the persistent context window,
> **accepting** that the model must semantically recognize VCS tasks to invoke the skill, which is mitigated by the hook's persistent reminder of the skill's existence.

### JJ-001: Use Hooks Over Skills for Jujutsu VCS Integration [Superseded by JJ-002]

> **In the context of** integrating Jujutsu (jj) VCS support into Claude Code,
> **facing** the challenge of overcoming the LLM's strong training bias toward `git`,
> **we decided** to use a SessionStart hook to automatically inject Jujutsu-specific context when a `.jj/` directory is detected,
> **to achieve** maximum reliability by ensuring VCS constraints are present before task analysis,
> **accepting** a token overhead of ~150-200 tokens per session.

**Status**: Superseded by JJ-002 (hybrid approach reduces token overhead ~75%)
