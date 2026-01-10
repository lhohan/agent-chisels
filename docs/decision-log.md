# Decision Log

Decisions are listed in reverse chronological order (most recent first).

### AC-001: Centralize skills at root level and symlink from plugins [Status: Yes]

> **In the context of** a repository containing both plugin-dependent and independent skills,
> **facing** the need for better skill discoverability, tooling support (OpenCode), and reduced coupling between skills and plugins,
> **we decided** to move actual skill files to a root `skills/` directory and use relative symlinks in `plugins/`,
> **to achieve** improved discoverability, direct OpenCode integration, and easier skill reuse,
> **accepting** the need to manually maintain symlinks when adding new skills and potential platform-specific symlink issues.
