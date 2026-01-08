# Decision Log

### PLG-001: Centralized marketplace.json with minimal plugin.json [Yes]

> **In the context of** defining plugin metadata for distribution and local development,  
> **facing** the need to support both claude-plugins.dev discovery and `--plugin-dir` local testing,  
> **we decided** to use `marketplace.json` as the authoritative source for all distribution metadata (version, description, category, keywords) and keep `plugin.json` minimal (name only),  
> **to achieve** single source of truth for distribution, discoverability on claude-plugins.dev, and reduced maintenance burden,  
> **accepting** that `name` must be duplicated in both files since `plugin.json` is required for local development.
