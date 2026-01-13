# Hook Installation Guide

This directory contains Git hooks that automatically detect skill changes and enforce version updates.

## Pre-Push Hook (Recommended)

**The pre-push hook is the recommended approach** because it works automatically for both Git and Jujutsu users with a single installation.

### Quick Installation

From the repository root:

```bash
# For both Git and Jujutsu repositories
ln -sf ../../../../.claude/skills/verify-release-readiness/hooks/pre-push .git/hooks/pre-push
```

### How It Works

- ✅ Automatically runs before every push (`git push` or `jj git push`)
- ✅ Detects changed skills (compares to `origin/main` or `main@origin`)
- ✅ Blocks pushes if skill versions haven't been updated
- ✅ Provides clear guidance on which versions need updating
- ✅ Works for both Git and Jujutsu with single installation
- ✅ Ensures you never publish skills with incorrect versions

### Why Pre-Push?

Unlike pre-commit hooks, **pre-push works automatically for both Git and Jujutsu** with a single installation:
- Git users run `git push` → triggers `.git/hooks/pre-push`
- Jujutsu users run `jj git push` → triggers `.git/hooks/pre-push` (same hook!)

No need for separate Jujutsu configuration in `.jj/repo/config.toml`.

### Bypassing (Not Recommended)

If you need to bypass the hook temporarily:

```bash
# Git
git push --no-verify

# Jujutsu
jj git push --no-verify
```

**Warning**: Bypassing the hook may result in publishing skills with incorrect versions.

---

## Pre-Commit Hook (Alternative)

A pre-commit hook is also available if you prefer earlier validation (validates before commits instead of before pushes).

### Quick Installation

#### For Git Repositories

```bash
ln -sf ../../../../.claude/skills/verify-release-readiness/hooks/pre-commit .git/hooks/pre-commit
```

#### For Jujutsu Repositories

Add to `.jj/repo/config.toml`:

```toml
[hooks]
pre-commit = ".claude/skills/verify-release-readiness/hooks/pre-commit"
```

### Trade-offs

**Advantages:**
- Catches issues earlier (at commit time)
- Enforces discipline commit-by-commit

**Disadvantages:**
- Requires separate configuration for Jujutsu users
- More intrusive (validates every commit vs only pushes)
- Jujutsu users must manually edit `.jj/repo/config.toml`

---

## Uninstalling

### Pre-Push Hook

```bash
rm .git/hooks/pre-push
```

### Pre-Commit Hook

**Git:**
```bash
rm .git/hooks/pre-commit
```

**Jujutsu:**
Remove the `[hooks]` section from `.jj/repo/config.toml`.

---

## Troubleshooting

### Hook doesn't run

- **Pre-push:** Ensure the symlink exists at `.git/hooks/pre-push` and is executable
- **Pre-commit (Git):** Ensure the symlink exists at `.git/hooks/pre-commit` and is executable
- **Pre-commit (Jujutsu):** Ensure the path in `.jj/repo/config.toml` is correct and the file is executable

### "jq: command not found"

Install `jq`:

```bash
# macOS
brew install jq

# Ubuntu/Debian
apt-get install jq

# Fedora
dnf install jq
```

### Hook reports "false positives"

This usually means:
1. A skill file has changed
2. But the version number hasn't been updated

**Solution:** Update the `version` field in the SKILL.md frontmatter following semantic versioning:
- Patch (0.1.0 → 0.1.1): Bug fixes, minor changes
- Minor (0.1.0 → 0.2.0): New features, backward compatible
- Major (0.1.0 → 1.0.0): Breaking changes

### Hook fails on first push

If you're pushing for the first time and `origin/main` doesn't exist locally:

```bash
git fetch origin main
```

This ensures `origin/main` exists for comparison.
