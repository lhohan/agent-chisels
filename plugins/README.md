# Plugins

This directory contains Claude Code plugins. Each plugin can include one or more skills, which are symlinked from [agentfiles/shared/skills/](../agentfiles/shared/skills).

## Plugin to Skill Mapping

| Plugin | Skills |
|--------|--------|
| [agent-tools](./agent-tools) | [evaluate-skills](../agentfiles/shared/skills/evaluate-skills), [write-agents-files](../agentfiles/shared/skills/write-agents-files) |
| [jj](./jj) | [detect-jujutsu](../agentfiles/shared/skills/detect-jujutsu), [use-jujutsu](../agentfiles/shared/skills/use-jujutsu) |
| [document-architectural-decisions](./document-architectural-decisions) | [document-architectural-decisions](../agentfiles/shared/skills/document-architectural-decisions) |
| [design-test-dsl](./design-test-dsl) | TBD |
| [modeling-c4-diagrams](./modeling-c4-diagrams) | [modeling-c4-diagrams](../agentfiles/shared/skills/modeling-c4-diagrams) |

For detailed descriptions of each skill, see [README.md](../README.md#available-skills).
