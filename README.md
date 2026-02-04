# Claude Code Workspace for OpenClaw Administration

**Mission**: Know OpenClaw better than it knows itself.

This is the Claude Code CLI working directory for administering and optimizing the OpenClaw multi-agent orchestration platform (v2026.2.2-3) running on WSL2 Linux.

## Overview

This workspace provides comprehensive tools and configurations for:
- Deep OpenClaw codebase analysis
- Gateway and agent troubleshooting
- Configuration optimization
- Documentation maintenance
- Custom automation creation

## Quick Start

```bash
# Initialize submodules (claude-code-templates)
git submodule update --init --recursive

# Install templates globally
cd claude-code-templates
./scripts/install-global.sh

# Load OpenClaw context
/openclaw-prime

# Check system health
/openclaw-status
```

## Structure

```
/home/claw/Claude/
├── claude-code-templates/     # Git submodule - production agents/commands/skills
├── .claude/                   # Global Claude CLI config (symlinks to templates)
├── CLAUDE.md                  # Comprehensive workspace documentation
└── README.md                  # This file
```

## Key Files

- **CLAUDE.md** - Complete guide to workspace capabilities, OpenClaw architecture, plugins, workflows
- **.gitignore** - Excludes sensitive files (.claude.json, credentials, settings)
- **claude-code-templates/** - Submodule containing reusable components

## OpenClaw Integration

This workspace operates alongside OpenClaw's Forge agent:

- **Claude Code (this workspace)**: Development, administration, configuration, code analysis
- **Forge (OpenClaw agent)**: Runtime orchestration, user interaction via Telegram
- **Shared**: `/home/claw/.openclaw/workspace/` for documentation and memory

## Installed Capabilities

### Plugins (11 total)
- TypeScript/Python LSP for code intelligence
- Greptile for AI-powered codebase search
- Code review and simplification tools
- Documentation maintenance
- Security guidance
- GitHub integration

### Custom Components
- `/openclaw-status` - System health check
- `/openclaw-prime` - Context loader
- `openclaw-troubleshooter` agent - Specialized debugging

### Templates (via submodule)
- 7 commands (/onboarding, /rca, /deep-prime, etc.)
- 8 agents (codebase-analyst, debugger, etc.)
- 5 skills (fork-terminal, LSP navigation, etc.)
- 4 workflows (feature-development, bug-investigation, etc.)

## Reference

- **OpenClaw Config**: `~/.openclaw/openclaw.json`
- **OpenClaw Source**: `~/.npm-global/lib/node_modules/openclaw/`
- **Workspace Documentation**: `~/.openclaw/workspace/CLAUDE-CODE-SETUP.md`
- **Gateway Logs**: `/tmp/openclaw/openclaw-YYYY-MM-DD.log`

## Common Tasks

**Analyze OpenClaw architecture:**
```bash
/onboarding
"Use greptile to explain how OpenClaw manages concurrent agents"
```

**Troubleshoot gateway issue:**
```bash
/openclaw-status
/rca "gateway won't start"
"Use openclaw-troubleshooter agent to diagnose"
```

**Optimize configuration:**
```bash
"Analyze openclaw.json and suggest model hierarchy improvements"
"Review sub-agent cost optimization"
```

**Fork parallel session:**
```bash
"Fork terminal use claude code to analyze the skill system"
```

## Updating Templates

```bash
cd claude-code-templates
git pull
./scripts/install-global.sh

# Or update from parent repo
git submodule update --remote claude-code-templates
```

## Notes

- This is a **workspace**, not a code project to build
- OpenClaw source code is in `~/.npm-global/lib/node_modules/openclaw/`
- Sensitive files (.claude.json, credentials) are gitignored
- Templates are managed as a submodule (1215-Labs/claude-code-templates)
- Fork-terminal requires X server (xterm configured)

---

**Created**: 2026-02-04
**OpenClaw Version**: 2026.2.2-3
**User**: Mike (mike5150@protonmail.ch)
