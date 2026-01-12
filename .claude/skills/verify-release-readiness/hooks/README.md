# Pre-Commit Hook Installation

This pre-commit hook automatically detects skill changes and enforces version updates before commits.

## Quick Installation

### For Git Repositories

From the repository root:

```bash
ln -sf ../../../../.claude/skills/verify-release-readiness/hooks/pre-commit .git/hooks/pre-commit
```

### For Jujutsu Repositories

Add to `.jj/repo/config.toml`:

```toml
[hooks]
pre-commit = ".claude/skills/verify-release-readiness/hooks/pre-commit"
```

## What It Does

- ✅ Automatically runs before every commit
- ✅ Detects changed skills (compares to `main@origin`)
- ✅ Blocks commits if skill versions haven't been updated
- ✅ Provides clear guidance on which versions need updating
- ✅ Ensures semantic versioning is followed

## Bypassing the Hook (Not Recommended)

If you need to bypass the hook temporarily:

```bash
# Git
git commit --no-verify

# Jujutsu
jj commit --no-edit  # (jj doesn't have --no-verify yet)
```

**Warning**: Bypassing the hook may result in publishing skills with incorrect versions.

## Uninstalling

### Git

```bash
rm .git/hooks/pre-commit
```

### Jujutsu

Remove the `[hooks]` section from `.jj/repo/config.toml`.

## Troubleshooting

### Hook doesn't run

- **Git**: Ensure the symlink is correct and the file is executable
- **Jujutsu**: Ensure the path in config.toml is correct and the file is executable

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

### Hook reports false positives

This usually means:
1. The skill file has changed
2. But the version number hasn't been updated

Solution: Update the `version` field in the SKILL.md frontmatter following semantic versioning.
