# Plugins

This directory contains Claude Code plugins. Each plugin can include one or more skills, which are symlinked from [agentfiles/shared/skills/](../agentfiles/shared/skills).

## Plugin to Skill Mapping

| Plugin | Skills |
|--------|--------|
| [agent-tools](./agent-tools) | [evaluate-skills](../agentfiles/shared/skills/evaluate-skills), [write-agents-files](../agentfiles/shared/skills/write-agents-files) |
| [jj](./jj) | *Skills migrated to [agentfiles](https://github.com/lhohan/agentfiles)* |
| [document-architectural-decisions](./document-architectural-decisions) | [document-architectural-decisions](../agentfiles/shared/skills/document-architectural-decisions) |
| [design-test-dsl](./design-test-dsl) | TBD |
| [modeling-c4-diagrams](./modeling-c4-diagrams) | [modelling-c4-diagrams](../agentfiles/shared/skills/modelling-c4-diagrams) |

For detailed descriptions of each skill, see [README.md](../README.md#available-skills).
