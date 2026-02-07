# agentsctl Spec v1

Status: Draft  
Date: 2026-02-07  
Scope: Skills only (v1)

## 1. Purpose

`agentsctl` standardizes shared skill intake and cross-agent skill sync without touching agent-specific configuration directly.

This spec defines:
- manifest format
- inventory format
- exact command output formats (including dry-run)
- deterministic ordering and verification rules

## 2. Design Constraints (v1)

- **Live edits:** Skills are edited in-place in their source locations. Sync uses symlinks (not copies).
- **Public/private split:** Skills come from two roots: `public` and `private`.
- **No name shadowing:** Skill names are globally unique across all configured sources. Any duplicate name is a conflict.
- **Stow-friendly:** Do **not** symlink an entire `skills/` directory into an agent. That blocks Stow folder folding and prevents clean composition with other packages (and agent-owned dirs like `.system`). Instead, install **one directory symlink per skill** under the agent’s live `skills/` directory.

## 3. Non-Goals (v1)

- No management of agent-specific config files (`settings.json`, hooks, runtime logs, caches).
- No management of `agents/`, `commands/`, or `prompts/` (future work).
- No Stow replacement. `agentsctl` may prepare/verify repo-local trees; deployment via Stow remains separate.
- No network fetches (no marketplace, no git pulls).

## 4. Required Paths (defaults for this repo)

- Repo root: `/Users/hans/dev/agent-chisels`
- Spec location: `/Users/hans/dev/agent-chisels/tools/agentsctl-spec-1.md`
- Manifest (default): `/Users/hans/dev/agent-chisels/agentfiles/agentsctl.toml`
- State dir: `/Users/hans/dev/agent-chisels/.build/agentsctl` (workspace for inventory + run reports)
- Public source: `/Users/hans/dev/agent-chisels/agentfiles/shared/skills`
- Effective home (runtime default): `/Users/hans` (override with `--home`)
- Private source (home-relative default): `${HOME}/dotfiles/agentsfiles/shared/skills`
- Inbox default (for `import`): `${HOME}/.codex/skills`

## 5. Model

### 5.1 Skill discovery

A directory is a **skill** when it contains `SKILL.md` or `skill.md` (case-insensitive; file or symlink).

Excluded from scans:
- `.DS_Store`
- editor temp files ending with `~`
- `.swp`, `.swo`

### 5.2 Profiles

A **profile** is a sync target for a coding agent. In v1, a profile defines one or more **output roots** (directories) where `agentsctl sync` ensures per-skill directory symlinks exist.

Profiles typically point at repo-local Stow package trees (recommended), not at `$HOME` directly.

## 6. CLI Contract

Binary: `agentsctl`

Commands:
- `import`
- `sync`
- `verify`

Global flags:
- `--manifest <path>` (default: `/Users/hans/dev/agent-chisels/agentfiles/agentsctl.toml`; accepts absolute, `~/...`, `${HOME}/...`)
- `--home <path>` (override effective home used for `~` and `${HOME}` expansion; useful for tests with symlinked fake homes)
- `--dry-run` (no changes to sources or profile outputs; writing under `state_dir` is allowed)
- `--json` (machine output; exact formats below)
- `--state-dir <path>` (overrides manifest; accepts absolute, `~/...`, `${HOME}/...`)

Exit codes:
- `0`: success
- `1`: runtime error (I/O, permissions, parse failure)
- `2`: validation error (manifest invalid, missing source/output root)
- `3`: conflict error (duplicate skill name across sources; illegal profile state)
- `4`: verification error (missing/incorrect link, broken link, unexpected managed entry)

## 7. Manifest Format (`agentsctl.toml`)

```toml
version = 1

[paths]
inbox = "${HOME}/.codex/skills"
state_dir = "/Users/hans/dev/agent-chisels/.build/agentsctl"

[sources.public]
path = "/Users/hans/dev/agent-chisels/agentfiles/shared/skills"

[sources.private]
path = "${HOME}/dotfiles/agentsfiles/shared/skills"

[profiles.codex]
# Where `agentsctl sync` writes per-skill directory symlinks.
# This can be a direct skills root or a subdir (if the agent supports nested mounts).
outputs = [
  "/Users/hans/dev/agent-chisels/agentfiles/codex/.codex/skills",
  "/Users/hans/dev/agent-chisels/agentfiles/codex/.agents/skills"
]
include_sources = ["public", "private"]
exclude = [".system"]

[profiles.claude_code]
outputs = ["/Users/hans/dev/agent-chisels/agentfiles/claude-code/.claude/skills"]
include_sources = ["public", "private"]
exclude = []

[profiles.opencode]
outputs = ["/Users/hans/dev/agent-chisels/agentfiles/opencode/.config/opencode/skills"]
include_sources = ["public", "private"]
exclude = []

[profiles.mistral_vibe]
outputs = ["/Users/hans/dev/agent-chisels/agentfiles/mistral-vibe/.vibe/skills"]
include_sources = ["public", "private"]
exclude = []
```

### 7.1 Manifest rules

- Path-valued fields (`paths.*`, `sources.*.path`, `profiles.*.outputs[]`) may be:
  - absolute paths
  - `~/...`
  - `${HOME}/...`
- `~` and `${HOME}` are expanded using the effective home directory (see 7.2), then validated.
- `sources.*.path` must be absolute after expansion.
- `profiles.*.outputs[]` must be absolute after expansion and must be directories (symlink-to-dir is allowed; `sync` may replace it with a real directory).
- `paths.state_dir` is a tool-owned workspace used for inventory and run reports.
- All emitted paths in inventory and command outputs must be expanded absolute paths (never raw `~` or `${HOME}` tokens).
- `exclude[]` matches **skill directory names** exactly.
- `include_sources` order is irrelevant in v1 (names are unique across sources).
- Duplicate skill names across included sources are always a conflict in v1 (no policy toggle).

### 7.2 Home resolution

Effective home directory precedence:
1. `--home <path>` CLI flag
2. Process `HOME` environment variable

Rules:
- `--home` must be an absolute path.
- If `--home` is not provided and process `HOME` is unset/empty, commands must fail with exit code `2` (`validation error`).
- The effective home is used only for path expansion (`~`, `${HOME}`); it does not change process working directory semantics.
- CLI path flags (`--manifest`, `--state-dir`) are expanded with the same effective home rules and validated before use.
- This enables hermetic tests where `${HOME}` targets a temporary or symlinked directory tree.

## 8. Inventory Format (`inventory.json`)

Location:
- `${state_dir}/inventory.json`

Purpose:
- canonical scan output for sources
- canonical scan output for profile outputs (what links exist today)
- input for `verify`

### 8.1 JSON shape (exact keys)

```json
{
  "schema_version": 1,
  "generated_at": "2026-02-07T12:00:00Z",
  "manifest_path": "/Users/hans/dev/agent-chisels/agentfiles/agentsctl.toml",
  "sources": [
    {
      "id": "public",
      "path": "/Users/hans/dev/agent-chisels/agentfiles/shared/skills",
      "exists": true
    }
  ],
  "profiles": [
    {
      "id": "claude_code",
      "outputs": [
        "/Users/hans/dev/agent-chisels/agentfiles/claude-code/.claude/skills"
      ],
      "include_sources": ["public", "private"],
      "exclude": []
    }
  ],
  "source_skills": [
    {
      "name": "evaluate-skills",
      "source_id": "public",
      "path": "/Users/hans/dev/agent-chisels/agentfiles/shared/skills/evaluate-skills",
      "has_skill_md": true,
      "skill_md_relpath": "SKILL.md",
      "content_sha256": "a63cb4a26de06f3476404a8f95f36a5f8ac7bc8b056cbf5b3731dce5dc450610",
      "file_count": 3,
      "byte_count": 31429,
      "files": [
        {
          "relpath": "SKILL.md",
          "type": "file",
          "sha256": "95f3e95f6bc4f27b6f724fd53d8f9467b749fd9f4016218c9785b5f1424da3ed",
          "size": 12234
        }
      ]
    }
  ],
  "profile_entries": [
    {
      "profile_id": "claude_code",
      "output": "/Users/hans/dev/agent-chisels/agentfiles/claude-code/.claude/skills",
      "skill": "evaluate-skills",
      "path": "/Users/hans/dev/agent-chisels/agentfiles/claude-code/.claude/skills/evaluate-skills",
      "type": "symlink_dir",
      "link_target": "/Users/hans/dev/agent-chisels/agentfiles/shared/skills/evaluate-skills",
      "link_target_resolved": "/Users/hans/dev/agent-chisels/agentfiles/shared/skills/evaluate-skills",
      "broken_link": false
    }
  ],
  "conflicts": [
    {
      "kind": "DUPLICATE_SKILL_NAME",
      "skill": "write-agents-files",
      "sources": ["public", "private"]
    }
  ]
}
```

### 8.2 Inventory rules

- `source_skills[]` sorted by:
  1. `name` ascending
  2. `source_id` ascending
- `files[]` sorted by `relpath` ascending.
- `profiles[]` sorted by `id` ascending; `outputs[]` sorted ascending.
- `profile_entries[]` sorted by:
  1. `profile_id` ascending
  2. `output` ascending
  3. `skill` ascending
- `conflicts[]` sorted by `kind`, then `skill` ascending.

### 8.3 Hashing rules (sources)

`content_sha256` is computed over all file records in sorted order:
- input string per file: `<relpath>\n<sha256>\n<size>\n`
- hash is sha256 of the concatenated bytes.

## 9. Sync Semantics (v1)

### 9.1 What `sync` manages

For each profile output directory, `agentsctl sync` ensures:
- every included source skill (minus `exclude`) exists as a **directory symlink** at:
  - `<output>/<skill_name> -> <source_skill_dir>`

**Do not** create a single link like `<output> -> <source_root>` (for either source).

### 9.2 Managed vs unmanaged entries

An entry `<output>/<name>` is **managed** iff:
- it is a symlink, and
- its resolved target path is within one of the configured `sources.*.path` roots.

`sync` may remove/update **managed** entries only. It must not delete or rewrite unmanaged entries.

### 9.3 Duplicate name handling

If the same `skill_name` exists in more than one included source, `sync` must fail with exit code `3` and emit a `CONFLICT` action.

## 10. Dry-Run Output Format (exact)

Dry-run prints the action plan. It must not modify sources or profile outputs.
Writing under `state_dir` is allowed (inventory and run report).

### 10.1 `--json` format (single JSON object to stdout)

Common envelope:

```json
{
  "schema_version": 1,
  "tool": "agentsctl",
  "command": "sync",
  "ok": true,
  "dry_run": true,
  "run_id": "20260207T120000Z-8f6f6d3d",
  "manifest_path": "/Users/hans/dev/agent-chisels/agentfiles/agentsctl.toml",
  "started_at": "2026-02-07T12:00:00Z",
  "finished_at": "2026-02-07T12:00:00Z",
  "actions": [],
  "summary": {},
  "error": null
}
```

Error envelope (`ok=false`) uses:

```json
{
  "schema_version": 1,
  "tool": "agentsctl",
  "command": "sync",
  "ok": false,
  "dry_run": true,
  "run_id": "20260207T120500Z-51a4ec33",
  "manifest_path": "/Users/hans/dev/agent-chisels/agentfiles/agentsctl.toml",
  "started_at": "2026-02-07T12:05:00Z",
  "finished_at": "2026-02-07T12:05:00Z",
  "actions": [],
  "summary": {},
  "error": {
    "code": "CONFLICT_DUPLICATE_SKILL_NAME",
    "message": "Skill name exists in more than one included source.",
    "details": {
      "skill": "write-agents-files",
      "sources": ["public", "private"]
    }
  }
}
```

### 10.2 `actions[]` schema (exact keys)

Each action object:

```json
{
  "id": 1,
  "op": "LINK_DIR",
  "status": "planned",
  "profile": "claude_code",
  "output": "/Users/hans/dev/agent-chisels/agentfiles/claude-code/.claude/skills",
  "skill": "evaluate-skills",
  "source_id": "public",
  "source_path": "/Users/hans/dev/agent-chisels/agentfiles/shared/skills/evaluate-skills",
  "target_path": "/Users/hans/dev/agent-chisels/agentfiles/claude-code/.claude/skills/evaluate-skills",
  "reason": "selected_by_profile"
}
```

Allowed `op` values (by command):
- `import`: `IMPORT_DIR`
- `sync`: `LINK_DIR`, `REMOVE_PATH`, `CONFLICT`
- `verify`: `VERIFY`

Allowed `status` values:
- `planned`
- `skipped`
- `conflict`
- `pass`
- `fail`

## 11. Command-Specific JSON Dry-Run Outputs

### 11.1 `import --dry-run --json`

`import` copies a skill directory from `paths.inbox` into a destination source root (default: `private` if present, else `public`).

```json
{
  "schema_version": 1,
  "tool": "agentsctl",
  "command": "import",
  "ok": true,
  "dry_run": true,
  "run_id": "20260207T121000Z-170f3e15",
  "manifest_path": "/Users/hans/dev/agent-chisels/agentfiles/agentsctl.toml",
  "started_at": "2026-02-07T12:10:00Z",
  "finished_at": "2026-02-07T12:10:00Z",
  "actions": [
    {
      "id": 1,
      "op": "IMPORT_DIR",
      "status": "planned",
      "profile": null,
      "output": null,
      "skill": "new-skill",
      "source_id": "inbox",
      "source_path": "/Users/hans/.codex/skills/new-skill",
      "target_path": "/Users/hans/dotfiles/agentsfiles/shared/skills/new-skill",
      "reason": "import_copy_default"
    }
  ],
  "summary": {
    "planned_imports": 1,
    "planned_links": 0,
    "planned_removals": 0,
    "conflicts": 0
  },
  "error": null
}
```

### 11.2 `sync --dry-run --json`

```json
{
  "schema_version": 1,
  "tool": "agentsctl",
  "command": "sync",
  "ok": true,
  "dry_run": true,
  "run_id": "20260207T121500Z-5d6e4c7b",
  "manifest_path": "/Users/hans/dev/agent-chisels/agentfiles/agentsctl.toml",
  "started_at": "2026-02-07T12:15:00Z",
  "finished_at": "2026-02-07T12:15:00Z",
  "actions": [
    {
      "id": 1,
      "op": "LINK_DIR",
      "status": "planned",
      "profile": "claude_code",
      "output": "/Users/hans/dev/agent-chisels/agentfiles/claude-code/.claude/skills",
      "skill": "evaluate-skills",
      "source_id": "public",
      "source_path": "/Users/hans/dev/agent-chisels/agentfiles/shared/skills/evaluate-skills",
      "target_path": "/Users/hans/dev/agent-chisels/agentfiles/claude-code/.claude/skills/evaluate-skills",
      "reason": "selected_by_profile"
    },
    {
      "id": 2,
      "op": "CONFLICT",
      "status": "conflict",
      "profile": "opencode",
      "output": "/Users/hans/dev/agent-chisels/agentfiles/opencode/.config/opencode/skills",
      "skill": "write-agents-files",
      "source_id": null,
      "source_path": null,
      "target_path": "/Users/hans/dev/agent-chisels/agentfiles/opencode/.config/opencode/skills/write-agents-files",
      "reason": "duplicate_name_across_sources"
    }
  ],
  "summary": {
    "profiles_scanned": 4,
    "skills_considered": 28,
    "planned_links": 27,
    "planned_imports": 0,
    "planned_removals": 0,
    "conflicts": 1
  },
  "error": null
}
```

### 11.3 `verify --dry-run --json`

```json
{
  "schema_version": 1,
  "tool": "agentsctl",
  "command": "verify",
  "ok": true,
  "dry_run": true,
  "run_id": "20260207T122000Z-fc10e671",
  "manifest_path": "/Users/hans/dev/agent-chisels/agentfiles/agentsctl.toml",
  "started_at": "2026-02-07T12:20:00Z",
  "finished_at": "2026-02-07T12:20:00Z",
  "actions": [
    {
      "id": 1,
      "op": "VERIFY",
      "status": "pass",
      "profile": "claude_code",
      "output": "/Users/hans/dev/agent-chisels/agentfiles/claude-code/.claude/skills",
      "skill": "evaluate-skills",
      "source_id": "public",
      "source_path": "/Users/hans/dev/agent-chisels/agentfiles/shared/skills/evaluate-skills",
      "target_path": "/Users/hans/dev/agent-chisels/agentfiles/claude-code/.claude/skills/evaluate-skills",
      "reason": "link_target_match"
    }
  ],
  "summary": {
    "skills_verified": 27,
    "missing": 0,
    "link_mismatches": 0,
    "broken_links": 0,
    "conflicts": 0
  },
  "error": null
}
```

## 12. Human Output Format (non-JSON, exact line grammar)

Non-JSON output uses fixed prefixes for scripting stability.

Prefixes:
- `INFO`
- `PLAN`
- `WARN`
- `ERROR`
- `SUMMARY`

Example (`sync --dry-run`):

```text
INFO run_id=20260207T121500Z-5d6e4c7b command=sync dry_run=true
PLAN op=LINK_DIR profile=claude_code output=/Users/hans/dev/agent-chisels/agentfiles/claude-code/.claude/skills skill=evaluate-skills source=public
WARN op=CONFLICT profile=opencode skill=write-agents-files reason=duplicate_name_across_sources
SUMMARY profiles_scanned=4 skills_considered=28 planned_links=27 conflicts=1
```

Field order is fixed.

## 13. Run Report Format (`runs/<run_id>.json`)

Location:
- `${state_dir}/runs/<run_id>.json`

Content:
- exactly the same object produced by `--json`, plus:

```json
{
  "artifacts": {
    "inventory_path": "/Users/hans/dev/agent-chisels/.build/agentsctl/inventory.json",
    "manifest_path": "/Users/hans/dev/agent-chisels/agentfiles/agentsctl.toml"
  }
}
```

## 14. Verification Rules

`verify` must fail if any condition is true:
- any source root is missing
- any profile output root is missing
- duplicate skill names exist across included sources
- an expected skill is missing from a profile output root
- a managed entry is a broken symlink
- a managed entry’s resolved target is not the expected source skill directory

`verify` may warn (not fail) on:
- unmanaged entries present in profile outputs

## 15. Implementation Notes

- All output arrays are sorted for deterministic diffs.
- `run_id` format: `%Y%m%dT%H%M%SZ-<8 hex chars>`.
- `--json` outputs a single JSON document to stdout and nothing else.
- For integration tests, prefer `--home /tmp/agentsctl-home` (or a symlink to a fixture tree) to avoid touching real user-home paths.
