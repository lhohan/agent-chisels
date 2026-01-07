# Plan: Initialize Claude Code Plugin Structure

**Status**: Plan Phase  
**Target**: First working Claude Code plugin with `skill-evaluator`

## Goal

Set up the first Claude Code plugin in the agent-chisels repository with a working `skill-evaluator` skill, establishing patterns and processes for future plugin development.

## Decision: Repository Structure

**Chosen: Option A** - Separate `plugin/` directory for Claude Code plugin.

**Rationale**: This repo will host configs for multiple AI agents (Claude Code, OpenCode, etc.). Keeping each agent's config in its own directory provides:
- Clean separation of concerns
- Clear naming convention (future: `opencode/`, `tools/`, etc.)
- No naming collisions between different agent ecosystems

**Structure**:
```
agent-chisels/
├── plugin/                          # Claude Code plugin root
│   ├── .claude-plugin/
│   │   └── plugin.json              # Plugin manifest
│   ├── skills/
│   │   └── skill-evaluator/
│   │       └── SKILL.md             # Skill definition
│   ├── commands/                    # Empty for now
│   ├── agents/                      # Empty for now
│   ├── hooks/                       # Empty for now
│   └── marketplace.json             # Self-publishing manifest
├── opencode/                        # Future: OpenCode configs
├── docs/
│   ├── plugin-dev-guide.md          # Plugin development workflow
│   └── ...
├── backlog/                         # Planning docs
└── .jj/                             # Version control
```

## Version Policy

**NEW**: Claude Code plugins should start with version **1.0.0** on first release.

**Rationale**:
- 0.x.x implies experimental/unstable status
- Plugins are typically tested thoroughly before release
- Starting at 1.0.0 signals production-ready
- Clearer communication to end users

**TODO**: Document this policy in `AGENTS.md` for future plugin development.

## Tasks

### Phase 1: Setup (High Priority)

- [ ] **Task 2**: Create plugin directory structure
  - `plugin/.claude-plugin/`
  - `plugin/skills/`
  - `plugin/skills/skill-evaluator/`
  - `plugin/commands/`
  - `plugin/agents/`
  - `plugin/hooks/`

- [ ] **Task 3**: Create `plugin/.claude-plugin/plugin.json` manifest
  - Version: **1.0.0** (first release)
  - Name: `agent-chisels`
  - Description: `Reusable skills for Claude Code and AI agents`

- [ ] **Task 4**: Create `plugin/skills/skill-evaluator/SKILL.md`
  - Source: Port from `~/.claude/skills/skill-evaluator/SKILL.md` as-is
  - Frontmatter with name, description (include trigger phrases), version 1.0.0
  - Full skill content (~200 lines)

- [ ] **Task 5**: Validate `plugin.json` with `jq`
  - Command: `jq . < plugin/.claude-plugin/plugin.json`
  - Should output valid JSON with no errors

### Phase 2: Testing (High Priority)

- [ ] **Task 6**: Test plugin locally
  - Command: `claude --plugin-dir $(pwd)/plugin`
  - Verify Claude Code starts without errors

- [ ] **Task 7**: Verify skill loads
  - In Claude Code session, run `/help`
  - Should show `agent-chisels` plugin
  - Should show available skills
  - Ask to "evaluate a skill" → should trigger `skill-evaluator`

### Phase 3: Publishing Setup (Medium Priority)

- [ ] **Task 8**: Create `plugin/marketplace.json`
  - Name: `agent-chisels`
  - Owner: Hans L'Hoest <agent-chisels@hanlho.simplelogin.com>
  - Homepage: https://github.com/lhohan/agent-chisels
  - Version: **1.0.0**

### Phase 4: Documentation (Medium Priority)

- [ ] **Task 9**: Update `docs/plugin-dev-guide.md`
  - Add note about subdirectory approach with `--plugin-dir`
  - Clarify skills are auto-discovered from `skills/` directory
  - Document SKILL.md frontmatter format (name, description, version)
  - Add note about trigger phrases in skill descriptions

- [ ] **Task 10**: Document version policy in `AGENTS.md`
  - Add section: "Claude Code Plugin Version Policy"
  - State: "New Claude Code plugins start at version 1.0.0"
  - Rationale: Implies production-ready state
  - Reference: This initialization as first example

## Files to Create

### 1. `plugin/.claude-plugin/plugin.json`

```json
{
  "name": "agent-chisels",
  "description": "Reusable skills for Claude Code and AI agents",
  "version": "1.0.0"
}
```

**Notes**:
- Version is 1.0.0 (first release)
- Name must match plugin identifier

### 2. `plugin/skills/skill-evaluator/SKILL.md`

Frontmatter:
```yaml
---
name: skill-evaluator
description: Evaluate Claude Code skills against best practices including size, structure, examples, and prompt engineering quality. Provides detailed assessment with actionable suggestions. Use when asked to "evaluate a skill", "review my skill", "check skill quality", or "analyze SKILL.md".
version: 1.0.0
---
```

Body: Full content from `~/.claude/skills/skill-evaluator/SKILL.md` (approximately 200 lines)

**Notes**:
- Description includes trigger phrases for discoverability
- Version is 1.0.0
- Content is ported as-is (no modifications)

### 3. `plugin/marketplace.json`

```json
{
  "name": "agent-chisels",
  "owner": {
    "name": "Hans L'Hoest",
    "email": "agent-chisels@hanlho.simplelogin.com"
  },
  "metadata": {
    "description": "Reusable skills for Claude Code and AI agents",
    "version": "1.0.0",
    "homepage": "https://github.com/lhohan/agent-chisels"
  },
  "plugins": [
    {
      "name": "agent-chisels",
      "source": "./",
      "description": "Reusable skills for Claude Code and AI agents",
      "version": "1.0.0",
      "category": "development",
      "keywords": ["skills", "evaluation", "quality"]
    }
  ]
}
```

**Notes**:
- Version is 1.0.0
- Repo URL: https://github.com/lhohan/agent-chisels
- Owner email: agent-chisels@hanlho.simplelogin.com

## Testing Commands

Once files are created, test in this order:

```bash
# 1. Validate JSON syntax
jq . < plugin/.claude-plugin/plugin.json
jq . < plugin/marketplace.json

# 2. Start Claude Code with local plugin
claude --plugin-dir $(pwd)/plugin

# 3. Inside Claude Code session:
/help                           # Verify plugin loads, shows skill

# 4. Test skill invocation
# Ask: "evaluate a skill"
# Or: "can you review my skill?"
# Should trigger skill-evaluator
```

## Expected Outcomes

✓ Plugin directory structure created  
✓ All JSON files valid  
✓ Plugin loads without errors  
✓ Skill appears in `/help` output  
✓ Skill can be invoked via natural language trigger phrases  
✓ Dev guide updated with learnings  
✓ Version policy documented  

## Learnings to Capture

After successful testing, document:
1. Any issues encountered with plugin discovery
2. How skills are auto-discovered (file locations, naming conventions)
3. How trigger phrases in descriptions affect skill invocation
4. Marketplace vs local plugin differences
5. Any updates needed to plugin-dev-guide.md for clarity

## References

- Dev guide: `docs/plugin-dev-guide.md`
- Reference repo: https://github.com/NTCoding/claude-skillz
- Official Claude Code docs: https://code.claude.com/docs/en/plugins
- Existing skill source: `~/.claude/skills/skill-evaluator/SKILL.md`
- GitHub repo: https://github.com/lhohan/agent-chisels

## Next Steps (Post-Implementation)

1. Test plugin end-to-end
2. Document any discoveries in AGENTS.md
3. Commit to jj with message: "init: set up Claude Code plugin structure with skill-evaluator"
4. Plan next skills to add to the plugin
