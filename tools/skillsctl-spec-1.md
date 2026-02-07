# skillsctl Spec v1

Status: Draft  
Date: 2026-02-06  
Scope: Skills only

## 1. Purpose

`skillsctl` standardizes shared skill intake and cross-agent skill sync without touching agent-specific configuration.

This spec defines:
- manifest format
- inventory format
- exact command output formats (including dry-run)
- verification and no-loss rules

## 2. Non-Goals (v1)

- No management of agent-specific config (`settings.json`, hooks, runtime logs, caches).
- No management of `agents/`, `commands/`, or `prompts/`.
- No Stow replacement in v1.

## 3. Required Paths

- Repo root: `/Users/hans/dev/agent-chisels`
- Tool root: `/Users/hans/dev/agent-chisels/tools/skillsctl`
- Manifest: `/Users/hans/dev/agent-chisels/manifests/skills-v1.toml`
- State dir: `/Users/hans/dev/agent-chisels/.build/skillsctl`
- Deploy dir: `/Users/hans/dev/agent-chisels/.build/deploy`
- Public source: `/Users/hans/dev/agent-chisels/agentfiles/shared/skills`
- Private source: `/Users/hans/dotfiles/agentsfiles/shared/skills`
- Inbox default: `/Users/hans/.codex/skills`

## 4. CLI Contract

Binary: `skillsctl`

Commands:
- `promote`
- `sync`
- `verify`

Global flags:
- `--manifest <path>` (default: `/Users/hans/dev/agent-chisels/manifests/skills-v1.toml`)
- `--dry-run`
- `--json` (machine output; exact formats below)
- `--state-dir <path>` (overrides manifest)

Exit codes:
- `0`: success
- `1`: runtime error (I/O, permissions, parse failure)
- `2`: validation error (manifest invalid, missing source)
- `3`: conflict error (name/hash conflict per policy)
- `4`: verification error (missing skill, checksum mismatch)

## 5. Manifest Format (`skills-v1.toml`)

```toml
version = 1

[paths]
inbox = "/Users/hans/.codex/skills"
state_dir = "/Users/hans/dev/agent-chisels/.build/skillsctl"
deploy_dir = "/Users/hans/dev/agent-chisels/.build/deploy"

[sources.public]
path = "/Users/hans/dev/agent-chisels/agentfiles/shared/skills"
required = true

[sources.private]
path = "/Users/hans/dotfiles/agentsfiles/shared/skills"
required = false

[resolution]
precedence = ["private", "public"]
on_name_conflict = "fail_if_hash_diff" # one of: fail_always, fail_if_hash_diff, prefer_precedence_if_hash_diff

[profiles.codex]
output = "/Users/hans/dev/agent-chisels/.build/deploy/codex/skills"
include_sources = ["public", "private"]
exclude = [".system"]

[profiles.claude_code]
output = "/Users/hans/dev/agent-chisels/.build/deploy/claude-code/skills"
include_sources = ["public", "private"]
exclude = []

[profiles.opencode]
output = "/Users/hans/dev/agent-chisels/.build/deploy/opencode/skills"
include_sources = ["public", "private"]
exclude = []

[profiles.mistral_vibe]
output = "/Users/hans/dev/agent-chisels/.build/deploy/mistral-vibe/skills"
include_sources = ["public", "private"]
exclude = []
```

## 6. Inventory Format (`inventory.json`)

Location:
- `/Users/hans/dev/agent-chisels/.build/skillsctl/inventory.json`

Purpose:
- canonical scan output for sources and generated deploy trees
- input for `verify`

### 6.1 JSON Shape (exact keys)

```json
{
  "schema_version": 1,
  "generated_at": "2026-02-06T18:15:20Z",
  "manifest_path": "/Users/hans/dev/agent-chisels/manifests/skills-v1.toml",
  "sources": [
    {
      "id": "public",
      "path": "/Users/hans/dev/agent-chisels/agentfiles/shared/skills",
      "required": true,
      "exists": true
    },
    {
      "id": "private",
      "path": "/Users/hans/dotfiles/agentsfiles/shared/skills",
      "required": false,
      "exists": true
    }
  ],
  "skills": [
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
        },
        {
          "relpath": "examples/EXAMPLE.md",
          "type": "file",
          "sha256": "be3a4c8a44c77f761756f66d2b4c8fa3647522bc988cf0f5d071523afe2b27de",
          "size": 19195
        }
      ]
    }
  ]
}
```

### 6.2 Inventory Rules

- `skills` array sorted by:
  1. `name` ascending
  2. `source_id` ascending
- `files` array sorted by `relpath` ascending.
- `content_sha256` is computed over all file records in sorted order:
  - input string per file: `<relpath>\n<sha256>\n<size>\n`
  - hash is sha256 of the concatenated bytes.
- Excluded from scan:
  - `.DS_Store`
  - editor temp files ending with `~`
  - `.swp`, `.swo`

## 7. Dry-Run Output Format (exact)

Dry-run is always a plan. No filesystem mutation is allowed.

### 7.1 `--json` format (single JSON object to stdout)

Common envelope:

```json
{
  "schema_version": 1,
  "tool": "skillsctl",
  "command": "sync",
  "ok": true,
  "dry_run": true,
  "run_id": "20260206T182700Z-8f6f6d3d",
  "manifest_path": "/Users/hans/dev/agent-chisels/manifests/skills-v1.toml",
  "started_at": "2026-02-06T18:27:00Z",
  "finished_at": "2026-02-06T18:27:00Z",
  "actions": [],
  "summary": {},
  "error": null
}
```

Error envelope (`ok=false`) uses:

```json
{
  "schema_version": 1,
  "tool": "skillsctl",
  "command": "verify",
  "ok": false,
  "dry_run": true,
  "run_id": "20260206T182900Z-51a4ec33",
  "manifest_path": "/Users/hans/dev/agent-chisels/manifests/skills-v1.toml",
  "started_at": "2026-02-06T18:29:00Z",
  "finished_at": "2026-02-06T18:29:00Z",
  "actions": [],
  "summary": {},
  "error": {
    "code": "VERIFY_MISSING_SKILL",
    "message": "Skill exists in source but is missing from generated profile output.",
    "details": {
      "profile": "opencode",
      "skill": "evaluate-skills"
    }
  }
}
```

### 7.2 `actions[]` schema (exact keys)

Each action object:

```json
{
  "id": 1,
  "op": "LINK_DIR",
  "status": "planned",
  "profile": "codex",
  "skill": "evaluate-skills",
  "source_id": "public",
  "source_path": "/Users/hans/dev/agent-chisels/agentfiles/shared/skills/evaluate-skills",
  "target_path": "/Users/hans/dev/agent-chisels/.build/deploy/codex/skills/evaluate-skills",
  "reason": "selected_by_precedence"
}
```

Allowed `op` values:
- `COPY_DIR`
- `LINK_DIR`
- `REMOVE_PATH`
- `SKIP_EQUIVALENT`
- `CONFLICT`
- `VERIFY_OK`
- `VERIFY_FAIL`

Allowed `status` values:
- `planned`
- `skipped`
- `conflict`
- `pass`
- `fail`

## 8. Command-Specific JSON Dry-Run Outputs

### 8.1 `promote --dry-run --json`

```json
{
  "schema_version": 1,
  "tool": "skillsctl",
  "command": "promote",
  "ok": true,
  "dry_run": true,
  "run_id": "20260206T183200Z-170f3e15",
  "manifest_path": "/Users/hans/dev/agent-chisels/manifests/skills-v1.toml",
  "started_at": "2026-02-06T18:32:00Z",
  "finished_at": "2026-02-06T18:32:00Z",
  "actions": [
    {
      "id": 1,
      "op": "COPY_DIR",
      "status": "planned",
      "profile": null,
      "skill": "new-skill",
      "source_id": "inbox",
      "source_path": "/Users/hans/.codex/skills/new-skill",
      "target_path": "/Users/hans/dotfiles/agentsfiles/shared/skills/new-skill",
      "reason": "promote_copy_default"
    }
  ],
  "summary": {
    "planned_copies": 1,
    "planned_links": 0,
    "conflicts": 0
  },
  "error": null
}
```

### 8.2 `sync --dry-run --json`

```json
{
  "schema_version": 1,
  "tool": "skillsctl",
  "command": "sync",
  "ok": true,
  "dry_run": true,
  "run_id": "20260206T183600Z-5d6e4c7b",
  "manifest_path": "/Users/hans/dev/agent-chisels/manifests/skills-v1.toml",
  "started_at": "2026-02-06T18:36:00Z",
  "finished_at": "2026-02-06T18:36:00Z",
  "actions": [
    {
      "id": 1,
      "op": "LINK_DIR",
      "status": "planned",
      "profile": "codex",
      "skill": "evaluate-skills",
      "source_id": "public",
      "source_path": "/Users/hans/dev/agent-chisels/agentfiles/shared/skills/evaluate-skills",
      "target_path": "/Users/hans/dev/agent-chisels/.build/deploy/codex/skills/evaluate-skills",
      "reason": "selected_by_precedence"
    },
    {
      "id": 2,
      "op": "CONFLICT",
      "status": "conflict",
      "profile": "opencode",
      "skill": "write-agents-files",
      "source_id": "private",
      "source_path": "/Users/hans/dotfiles/agentsfiles/shared/skills/write-agents-files",
      "target_path": "/Users/hans/dev/agent-chisels/.build/deploy/opencode/skills/write-agents-files",
      "reason": "same_name_different_hash"
    }
  ],
  "summary": {
    "profiles_scanned": 4,
    "skills_considered": 28,
    "planned_links": 27,
    "planned_copies": 0,
    "planned_removals": 0,
    "conflicts": 1
  },
  "error": null
}
```

### 8.3 `verify --dry-run --json`

```json
{
  "schema_version": 1,
  "tool": "skillsctl",
  "command": "verify",
  "ok": true,
  "dry_run": true,
  "run_id": "20260206T184000Z-fc10e671",
  "manifest_path": "/Users/hans/dev/agent-chisels/manifests/skills-v1.toml",
  "started_at": "2026-02-06T18:40:00Z",
  "finished_at": "2026-02-06T18:40:00Z",
  "actions": [
    {
      "id": 1,
      "op": "VERIFY_OK",
      "status": "pass",
      "profile": "codex",
      "skill": "evaluate-skills",
      "source_id": "public",
      "source_path": "/Users/hans/dev/agent-chisels/agentfiles/shared/skills/evaluate-skills",
      "target_path": "/Users/hans/dev/agent-chisels/.build/deploy/codex/skills/evaluate-skills",
      "reason": "hash_match"
    }
  ],
  "summary": {
    "skills_verified": 27,
    "missing": 0,
    "hash_mismatches": 0,
    "unexpected_targets": 0
  },
  "error": null
}
```

## 9. Human Output Format (non-JSON, exact line grammar)

For scripting stability, non-JSON output uses fixed prefixes.

Prefixes:
- `INFO`
- `PLAN`
- `WARN`
- `ERROR`
- `SUMMARY`

Example (`sync --dry-run`):

```text
INFO run_id=20260206T183600Z-5d6e4c7b command=sync dry_run=true
PLAN op=LINK_DIR profile=codex skill=evaluate-skills source=public
WARN op=CONFLICT profile=opencode skill=write-agents-files reason=same_name_different_hash
SUMMARY profiles_scanned=4 skills_considered=28 planned_links=27 conflicts=1
```

This format is normative. Field order is fixed.

## 10. Run Report Format (`runs/<run_id>.json`)

Location:
- `/Users/hans/dev/agent-chisels/.build/skillsctl/runs/<run_id>.json`

Content:
- exactly the same object produced by `--json`, plus:

```json
{
  "artifacts": {
    "inventory_path": "/Users/hans/dev/agent-chisels/.build/skillsctl/inventory.json",
    "manifest_path": "/Users/hans/dev/agent-chisels/manifests/skills-v1.toml"
  }
}
```

## 11. Verification Rules (no-loss)

`verify` must fail if any condition is true:
- source skill included by profile is missing in profile output
- source and target hashes differ
- required source root missing
- unresolved conflicts remain

`verify` may warn (not fail) on:
- optional source missing (`required=false`)
- duplicate-equivalent skills across sources (same hash)

## 12. Implementation Notes

- All output arrays are sorted for deterministic diffs.
- `run_id` format: `%Y%m%dT%H%M%SZ-<8 hex chars>`.
- Always write run report, even on failure.
- `--json` outputs a single JSON document to stdout and nothing else.
