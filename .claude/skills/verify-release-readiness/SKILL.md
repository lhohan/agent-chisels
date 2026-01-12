---
name: verify-release-readiness
version: 0.1.0
description: Verify release readiness by detecting changed skills, checking version updates, and running validation scripts. Use before creating releases or publishing to marketplace.
---

# Verify Release Readiness

Use this skill to prepare skills for release. It detects which skills have changed since the last release and reports whether versions were updated accordingly.

This skill automates the release preparation workflow and ensures all skills have proper version updates.

## Automated vs Manual Usage

This skill can be used in two ways:

1. **Automated (Recommended)**: Install the pre-commit hook to automatically enforce version updates on every commit
2. **Manual**: Invoke this skill manually before publishing to marketplace

### Installing the Pre-Commit Hook

**RECOMMENDED**: Install the pre-commit hook to make version checking deterministic:

```bash
# For Git repositories
ln -sf ../../../../.claude/skills/verify-release-readiness/hooks/pre-commit .git/hooks/pre-commit

# For Jujutsu repositories
# Add to .jj/repo/config.toml:
# [hooks]
# pre-commit = ".claude/skills/verify-release-readiness/hooks/pre-commit"
```

Once installed:
- ✅ Automatically runs before every commit
- ✅ Blocks commits if skill versions aren't updated
- ✅ Provides clear guidance on which versions need updating
- ✅ Ensures you never forget to update versions

The hook uses the same detection script as this skill, so behavior is consistent.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Release Preparation Workflow](#release-preparation-workflow)
- [Tips and Best Practices](#tips-and-best-practices)
- [Error Handling](#error-handling)
- [Example Output](#example-output)

## Prerequisites

Before using this skill:
- You are in a Jujutsu repository with a `main` bookmark and `main@origin` (remote tracking bookmark)
- `jq` is installed (for JSON parsing)
- You have the `scripts/verify-skills-static.sh` and `scripts/verify-skills-opencode.sh` scripts available
- **(For automated mode)**: Pre-commit hook installed (see above)

## Release Preparation Workflow

### Step 1: Detect Changes

Run the detection script using the Bash tool:

```bash
bash .claude/skills/verify-release-readiness/scripts/detect-changes.sh
```

This script:
- Compares your working copy to the last published release (`main@origin` bookmark)
- Identifies all changed skills since the last release
- Extracts current and published versions for each skill
- Outputs JSON format

**Exit codes**:
- 0: Changes detected
- 1: No changes found
- 2: Error (not a jj repo, invalid main@origin bookmark, etc.)

**Optional: Compare against a different revision**:

```bash
bash .claude/skills/verify-release-readiness/scripts/detect-changes.sh <revision>
```

Examples:
- `bash .claude/skills/verify-release-readiness/scripts/detect-changes.sh main` - Compare against local main bookmark
- `bash .claude/skills/verify-release-readiness/scripts/detect-changes.sh @-` - Compare against parent commit

### Step 2: Parse and Report Findings

After running the script:

1. **Verify the JSON is valid** - Inspect the output structure
2. **Identify changed skills** - Look for skills in the `changed_skills` array
3. **Check version status** - For each skill:
   - If `needs_update: false` → Version was properly updated ✓
   - If `needs_update: true` → Version needs manual update ⚠

### Step 3: Report to User

Present the findings in a clear format:

```
Found X changed skills:

✓ skill-name-1
  - Current version: 0.2.0
  - Main version: 0.1.0
  - Status: Version updated ✓
  - Changed files: skills/skill-name-1/SKILL.md

⚠ skill-name-2
  - Current version: 0.3.0
  - Main version: 0.3.0
  - Status: Version NOT updated ⚠
  - Changed files: skills/skill-name-2/SKILL.md, skills/skill-name-2/README.md
```

### Step 4: Wait for User to Update Versions

For skills marked with ⚠ (needs_update: true):

Tell the user: **"Please manually update the version field in the SKILL.md frontmatter for the following skills: [list them]"**

The user should:
- Open the SKILL.md file for each flagged skill
- Update the version field following semantic versioning (patch/minor/major)
- Save the file

Wait for the user to indicate they're done.

### Step 5: Run Verification Scripts

Once user confirms versions are updated, run the verification scripts:

```bash
bash scripts/verify-skills-static.sh
bash scripts/verify-skills-opencode.sh
```

Both should output TAP format with all tests passing. Report any failures to the user.

### Step 6: Provide Release Summary

After verification passes, summarize:

```
Release preparation complete:
- X skills changed
- Y versions manually updated
- All verification tests passed ✓

Ready to commit and release!
```

## Tips and Best Practices

- Always check the release summary before committing
- Ensure all verification tests pass before pushing to remote
- Use semantic versioning: patch for fixes, minor for features, major for breaking changes

## Error Handling

**If detection script fails (exit code 2)**:
- Check if you're in a jj repository: `jj st`
- Verify the `main@origin` (remote) bookmark exists: `jj bookmark list`
- Report the error to the user with the script's error message

**If no changes detected (exit code 1)**:
- Tell the user: "No skill changes detected since the last published release (main@origin)"
- Suggest they verify they've made changes and committed them locally
- They can also use `bash .claude/skills/verify-release-readiness/scripts/detect-changes.sh main` to compare against the local main bookmark instead

**If verification fails**:
- Show the TAP output to the user
- Identify which tests failed
- Suggest fixes (e.g., ensure required fields are present in SKILL.md frontmatter)

## Example Output

```json
{
  "changed_skills": [
    {
      "name": "detecting-jujutsu",
      "current_version": "0.2.0",
      "main_version": "0.1.0",
      "needs_update": false,
      "changed_files": ["skills/detecting-jujutsu/SKILL.md"]
    },
    {
      "name": "using-jujutsu",
      "current_version": "0.2.0",
      "main_version": "0.2.0",
      "needs_update": true,
      "changed_files": ["skills/using-jujutsu/SKILL.md", "skills/using-jujutsu/scripts/detect.sh"]
    }
  ]
}
```
