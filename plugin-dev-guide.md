# Claude Code Plugin Workflow – Updated Guide

You manage this with a single plugin repo that you can run locally via `--plugin-dir`, and then publish as a "marketplace plugin" that you install like any other plugin.[1][2]

## Core workflow

- Develop your skills in a normal jj repo with the standard structure:  
  `agent-chisels/.claude-plugin/plugin.json`, plus optional `commands/`, `agents/`, `skills/`, `hooks/`, `.mcp.json`, `.lsp.json`, etc.[3][1]
- While iterating, point Claude Code at the local directory with:  
  `claude --plugin-dir $(pwd)/agent-chisels` and then use `/help` or your slash commands to test.[1]
- Once it works, publish the repo (e.g. GitHub) and expose it via a marketplace manifest so you can install it on any machine with `/plugin install`.[2]

## Local development loop

1. Create folder and manifest:

   ```bash
   mkdir -p agent-chisels/.claude-plugin
   cat > agent-chisels/.claude-plugin/plugin.json << 'EOF'
   {
     "name": "agent-chisels",
     "description": "Reusable skills for Claude Code and AI agents",
     "version": "0.1.0"
   }
   EOF
   ```

   This manifest is what Claude Code reads to see the plugin.[1] **Note:** Always use valid JSON; you can validate with `jq . < agent-chisels/.claude-plugin/plugin.json` or an online JSON validator before running Claude Code.

2. Initialize your jj repo:

   ```bash
   cd agent-chisels
   jj init
   jj branch create main
   ```

   jj works best with a main branch as your default. Unlike git, jj treats all changes as commits automatically, so there's no staging area.[1]

3. Add a simple slash command:

   ```bash
   mkdir -p commands
   cat > commands/hello.json << 'EOF'
   {
     "name": "hello",
     "description": "Test command",
     "args": [],
     "script": {
       "command": "bash",
       "args": ["-lc", "echo 'Hello from agent-chisels'"]
     }
   }
   EOF
   ```

   Commands in `commands/` get auto-wired as `/agent-chisels:hello` once the plugin is loaded.[1]

4. Commit your work:

   ```bash
   jj add commands/hello.json
   jj commit -m "Add hello command"
   ```

   In jj, every change is a commit. There's no separate staging workflow like git.[1]

5. Run Claude Code with the plugin:

   ```bash
   claude --plugin-dir $(pwd)
   ```

   **Important:** Always use an absolute path (or `$(pwd)` to expand relative paths). Relative paths like `./agent-chisels` may not resolve correctly when Claude Code starts.[1]

   In the session, you can now run `/agent-chisels:hello`.[1]

6. Iterate and reload:
   - **File changes (commands, agents, skills):** Exit Claude Code with `exit` or Ctrl+C, then restart with `claude --plugin-dir $(pwd)`. Plugin files are loaded at startup, not hot-reloaded.
   - **`plugin.json` changes:** Requires a full restart of Claude Code.
   - **Adding new files:** As long as you keep the `plugin.json` valid and the directory structure intact (`commands/`, `agents/`, `skills/`, etc.), new files in those folders will be picked up on the next restart.[3][1]
   - **jj workflow:** Make changes, commit with `jj commit`, then restart Claude Code. Use `jj log` to see your change history.

## Understanding skill components

Beyond basic commands, your skills repo can include:

- **`commands/`**: Slash commands that users invoke directly (e.g., `/agent-chisels:analyze`). Good for one-off utilities.[1]
- **`agents/`**: Autonomous workflows that Claude Code can trigger with `/agent-chisels:agent-name`. Define complex multi-step tasks here.[3]
- **`skills/`**: Reusable functions that agents or commands can call. Organize domain-specific logic as skills for maximum reusability.[3]
- **`hooks/`**: Lifecycle hooks that fire on plugin load, session start, etc. Useful for initialization.[3]
- **`.mcp.json`**: Model Context Protocol configuration for integrating external tools, APIs, or local services. Makes your skills vendor-agnostic.[3]
- **`.lsp.json`**: Language Server Protocol config for syntax checking or code intelligence in specific languages.[3]

Start with commands, then add agents and skills as your collection grows.

## Self-publishing so you can install it

To use your skills on any machine, wrap them in a marketplace:

1. Create a marketplace manifest (e.g. in the repo root):

   ```json
   {
     "name": "agent-chisels",
     "description": "Reusable skills for Claude Code and AI agents",
     "plugins": [
       {
         "name": "agent-chisels",
         "description": "Reusable skills for Claude Code and AI agents",
         "version": "0.1.0",
         "repo": "https://github.com/yourname/agent-chisels"
       }
     ]
   }
   ```

   Commit this to your jj repo:

   ```bash
   jj add marketplace.json
   jj commit -m "Add marketplace manifest"
   ```

   Marketplaces define which plugins are available and where to fetch them from.[2] **Security note:** Users installing from third-party marketplaces should review the plugin source code before installation, especially for plugins that request elevated permissions or handle sensitive data.

2. Host that JSON somewhere reachable (GitHub raw URL is enough):

   ```bash
   # GitHub raw URL pattern
   https://raw.githubusercontent.com/yourname/agent-chisels/main/marketplace.json
   ```

   **Availability tip:** If the marketplace URL becomes unavailable, existing installations remain functional, but users cannot update or reinstall the plugin. Use a URL you control long-term.

3. On any machine:

   ```bash
   # Add the agent-chisels marketplace
   /plugin marketplace add agent-chisels https://raw.githubusercontent.com/yourname/agent-chisels/main/marketplace.json

   # Install the plugin
   /plugin install agent-chisels@agent-chisels

   # Restart Claude Code so it loads the plugin
   /restart
   ```

   After that, your skills are active without `--plugin-dir`.[4][2]

## Version bumping and updates

When you've reached a stable point and want to release a new version:

1. **Bump the version** in `.claude-plugin/plugin.json`:

   ```json
   {
     "name": "agent-chisels",
     "description": "Reusable skills for Claude Code and AI agents",
     "version": "0.2.0"
   }
   ```

   Follow semantic versioning (major.minor.patch).[2]

2. **Update your marketplace manifest** to reflect the new version:

   ```json
   {
     "name": "agent-chisels",
     "description": "Reusable skills for Claude Code and AI agents",
     "version": "0.2.0",
     "repo": "https://github.com/yourname/agent-chisels"
   }
   ```

3. **Commit and tag** your changes:

   ```bash
   jj add .claude-plugin/plugin.json marketplace.json
   jj commit -m "Bump version to 0.2.0"
   jj tag create v0.2.0
   ```

   Then push to your remote (e.g., GitHub):

   ```bash
   jj git push
   ```

4. **On other machines**, update via:

   ```bash
   /plugin update agent-chisels@agent-chisels
   /restart
   ```

   Claude Code will fetch the latest `plugin.json` from your repo and apply updates.[2][1]

## Using both local and published versions

- **For fast iteration on one machine:** Stick with `--plugin-dir $(pwd)` pointed at your working copy. Changes require a restart but stay local.[1]
- **When reaching a stable point:** Bump `version` in `plugin.json`, commit, tag with jj, push, update your marketplace manifest, then install/update via `/plugin install agent-chisels@agent-chisels` on other machines.[2][1]
- **To dogfood the published form on the same machine:** 
  1. Exit Claude Code
  2. Remove the `--plugin-dir` flag and run `claude` normally
  3. Install from your marketplace with `/plugin install agent-chisels@agent-chisels`
  4. For development, switch back to `--plugin-dir` mode to test locally[2][1]

## A realistic skills collection structure

Once you've mastered basic commands, your collection grows like this:

```
agent-chisels/
├── .jj/                    # jj repo config
├── .claude-plugin/
│   └── plugin.json          # Core manifest
├── commands/
│   ├── analyze.json         # Slash command
│   ├── validate.json        # Another command
│   └── transform.json       # etc.
├── agents/
│   ├── workflow.json        # Multi-step agent
│   └── pipeline.json        # Another agent
├── skills/
│   ├── data-fetch.json      # Reusable skill
│   ├── parse-utils.json     # Helper skill
│   └── format-output.json   # Output formatting
├── .mcp.json                # External tool integrations
├── .lsp.json                # Language server config (optional)
├── README.md                # Documentation & usage guide
├── LICENSE                  # License
└── marketplace.json         # Self-publishing manifest
```

Start simple (just `commands/`), then add agents and skills as your collection's scope expands.

## jj-specific workflows

**Seeing your change history:**
```bash
jj log
```

Displays your entire commit tree. Unlike git, jj shows all commits even if they're not on a branch.[1]

**Updating main before publishing:**
```bash
jj rebase -d main
```

Rebase your current changes onto main if needed.[1]

**Squashing or editing commits:**
```bash
jj squash              # Merge current commit into parent
jj describe            # Edit the current commit message
```

Much simpler than git's interactive rebase.[1]

**Viewing diffs:**
```bash
jj diff               # See changes in current commit
jj diff -r @~        # See changes in previous commit
```

## Troubleshooting

**Plugin not loading?**
- Verify `plugin.json` is valid JSON: `jq . < .claude-plugin/plugin.json`
- Check that the path to `--plugin-dir` is absolute: use `$(pwd)` instead of `./agent-chisels`
- Ensure the `.claude-plugin/` directory exists at the exact path you're pointing to
- Restart Claude Code completely (exit and rerun the `claude` command)

**Plugin loaded but commands don't appear?**
- Run `/help` to list loaded plugins and their commands
- Verify command files are in `commands/` and use valid JSON
- Restart Claude Code after adding new command files

**Marketplace plugin won't install?**
- Double-check the marketplace URL is accessible (test in a browser)
- Ensure your `plugin.json` and marketplace manifest have matching names and versions
- Run `/plugin marketplace list` to confirm the marketplace is registered
- Try `/plugin marketplace remove agent-chisels` and re-add if needed

**Changes not taking effect after editing files?**
- You *must* restart Claude Code (exit and rerun `claude`)—there is no hot-reload
- If only `plugin.json` changed, still restart Claude Code fully
- On published plugins, run `/plugin update agent-chisels@agent-chisels` then `/restart`

**jj push not working?**
- Ensure your jj repo is linked to a remote: `jj git remote list`
- If needed, add a remote: `jj git remote add origin https://github.com/yourname/agent-chisels`
- Then push: `jj git push`

---

**If you share your current layout (repo structure and how you're launching Claude Code), a concrete command set for your exact setup can be sketched out.**

### Sources
[1] Create plugins - Claude Code Docs https://code.claude.com/docs/en/plugins
[2] Create and distribute a plugin marketplace - Claude Code Docs https://code.claude.com/docs/en/plugin-marketplaces
[3] plugin install https://code.claude.com/docs/en/plugins-reference
[4] How to Install Plugins in Claude Code CLI (Easy Guide) - YouTube https://www.youtube.com/watch?v=_zbRr0jnMBY
