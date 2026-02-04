# Git Submodule Notes

## Overview

`claude-code-templates` is managed as a **git submodule** to track the specific version of templates used with this workspace.

**Repository**: https://github.com/1215-Labs/claude-code-templates.git

## Why Submodule?

✅ Version control - track which template version we're using
✅ Independent updates - update templates separately from workspace config
✅ Proper dependency management - templates are external dependency
✅ Reproducibility - others can clone workspace with correct template version

## Common Operations

### Clone This Repo (First Time)

```bash
git clone <repo-url>
cd Claude
git submodule update --init --recursive
./claude-code-templates/scripts/install-global.sh
```

### Update Templates to Latest

```bash
cd claude-code-templates
git pull origin main
cd ..
git add claude-code-templates
git commit -m "Update claude-code-templates to latest version"
```

Or from parent repo:
```bash
git submodule update --remote claude-code-templates
git add claude-code-templates
git commit -m "Update claude-code-templates submodule"
```

### Check Submodule Status

```bash
git submodule status
```

### View Submodule Commit

```bash
cd claude-code-templates
git log -1
```

## Local Modifications

### fork_terminal.py Executable Bit

The upstream repo doesn't set the executable bit on `fork_terminal.py`, but it's needed since the file has a shebang (`#!/usr/bin/env -S uv run`).

**Solution**: A post-checkout hook automatically runs `chmod +x` on this file after checkout/submodule updates.

**Location**: `.git/hooks/post-checkout`

This modification is intentionally kept as a local change and not committed to the submodule.

## After Submodule Updates

```bash
# Reinstall templates globally
cd claude-code-templates
./scripts/install-global.sh

# Verify fork-terminal works
/home/claw/.claude/skills/fork-terminal/tools/fork_terminal.py "echo 'test'"
```

## Submodule Configuration

**.gitmodules:**
```ini
[submodule "claude-code-templates"]
	path = claude-code-templates
	url = https://github.com/1215-Labs/claude-code-templates.git
```

## Troubleshooting

### Submodule is Empty After Clone

```bash
git submodule update --init --recursive
```

### Submodule Has Uncommitted Changes

This is normal if fork_terminal.py shows as modified (executable bit difference).

To ignore:
```bash
cd claude-code-templates
git update-index --assume-unchanged .claude/skills/fork-terminal/tools/fork_terminal.py
```

### Reset Submodule to Tracked Commit

```bash
git submodule update --force
```

## Best Practices

1. **Don't commit inside submodule** - update from upstream instead
2. **Track submodule commit** - commit parent repo after updating submodule
3. **Document breaking changes** - if template update breaks workflows, document here
4. **Test after updates** - run `./scripts/install-global.sh` after updating

## Alternatives Considered

### Moving Templates Outside Repo
❌ Lose version tracking
❌ Harder to document dependency
❌ Manual setup for new clones

### Copying Templates Directly
❌ No update mechanism
❌ Duplicate code
❌ Divergence from upstream

### Git Submodule (Selected)
✅ Version tracking
✅ Easy updates
✅ Standard practice
✅ Reproducible setup

---

**Created**: 2026-02-04
**Submodule**: claude-code-templates @ main branch
