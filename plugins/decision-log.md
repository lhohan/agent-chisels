# Decision Log

### PLG-002: Root-level .claude-plugin directory for marketplace.json [Yes]

> **In the context of** organizing the agent-chisels repository structure with multiple plugins,  
> **facing** the need to publish a single marketplace.json that aggregates all plugins while keeping individual plugin directories clean,  
> **we decided** to move `marketplace.json` from `plugins/` to `.claude-plugin/` at the repository root,  
> **to achieve** clear separation between plugin implementation (in `plugins/[plugin-name]/`) and marketplace distribution metadata (at root), improved discoverability of the marketplace file, and alignment with Claude Code's `.claude-plugin/` convention,  
> **accepting** that the marketplace URL changes to `.claude-plugin/marketplace.json` and users must update their marketplace subscription URL when migrating.

### PLG-001: Centralized marketplace.json with minimal plugin.json [Yes]

> **In the context of** defining plugin metadata for distribution and local development,  
> **facing** the need to support both claude-plugins.dev discovery and `--plugin-dir` local testing,  
> **we decided** to use `marketplace.json` as the authoritative source for all distribution metadata (version, description, category, keywords) and keep `plugin.json` minimal (name only),  
> **to achieve** single source of truth for distribution, discoverability on claude-plugins.dev, and reduced maintenance burden,  
> **accepting** that `name` must be duplicated in both files since `plugin.json` is required for local development.
