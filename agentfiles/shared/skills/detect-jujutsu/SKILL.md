---
name: detect-jujutsu
description: Verify if the current repository uses Jujutsu (jj) instead of git. Use this skill when you or the user needs to confirm the version control system (VCS) state before performing operations.
version: 0.2.1
---

# Detecting Jujutsu (jj)

This repository uses **Jujutsu (jj)** as its version control if confirmed by the authoritative detection script built for this project.

## Detection Procedure

To verify if this is a Jujutsu repository, you **MUST** run the following script using the Bash tool:

```bash
bash skills/detect-jujutsu/scripts/detect-jj.sh
```

This works from the repository root directory.

### Interpreting the Result

- **Exit Code 0 (Success)**: This is a Jujutsu repository.
  - **Action**: Use `jj` commands exclusively.
  - **Next Step**: **Invoke the `use-jujutsu` skill** for detailed command reference and workflows.
- **Exit Code 1 (Not JJ)**: This is a standard Git repository.
  - **Action**: Use standard `git` workflows.
- **Exit Code 2 (Indeterminate)**: An error occurred (e.g., `jj` not installed or not in a git repo).
  - **Action**: Follow the "Next steps" printed by the script.

## Outcome

Always respect the detection result. If Jujutsu is confirmed, do not use `git` commands unless explicitly requested by the user for remote synchronization tasks.
