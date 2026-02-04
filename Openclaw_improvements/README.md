# OpenClaw Improvements Package

Portable improvements for OpenClaw based on deep codebase analysis.

## Quick Install

```bash
cd Openclaw_improvements
chmod +x install.sh
./install.sh
```

Or dry run first:
```bash
./install.sh --dry-run
```

## What's Included

### Configuration Changes
| Setting | Before | After | Reason |
|---------|--------|-------|--------|
| `subagents.maxConcurrent` | 8 | 4 | Prevents resource exhaustion |
| `diagnostics.enabled` | false | true | Enables cost tracking |
| `cacheTrace.enabled` | false | true | Cache performance monitoring |

### Custom Skills

**config-validate** - Validates `openclaw.json` for common errors
- Triggers: "validate config", "check openclaw config"
- Checks: JSON syntax, required sections, API keys, concurrency limits, security

**cost-report** - Generates usage and cost estimates
- Triggers: "cost report", "usage report", "token usage"
- Sources: Gateway logs, session files, model distribution

### Agent Roles

Pre-defined specialist agents with optimized model selection:

| Role | Model | Use Case |
|------|-------|----------|
| `researcher` | Kimi K2.5 | Information gathering, web research |
| `coder` | Claude Opus | Implementation, bug fixes |
| `reviewer` | Kimi K2 Thinking | Code review, QA |

Spawn with:
```javascript
sessions_spawn({ role: "researcher", task: "Research [topic]" })
```

### Scripts

**validate-skills.sh** - Validates skill configurations
```bash
~/.openclaw/workspace/scripts/validate-skills.sh [skill-name]
```

### Enhanced Commands

**openclaw-status.md** - Comprehensive health check (10 diagnostic sections)

### Forge Onboarding

The installer automatically appends an onboarding note to Forge's `MEMORY.md`, informing it about:
- New agent roles and spawn patterns
- Available skills (config-validate, cost-report)
- Updated concurrency limits
- Reference to CAPABILITIES.md for full documentation

Forge will see this on next main session startup.

## Directory Structure

```
Openclaw_improvements/
├── install.sh              # Automated installer
├── config-patch.json       # Configuration changes (for reference)
├── agents-patch.md         # Manual patch for AGENTS.md
├── tools-patch.md          # Manual patch for TOOLS.md
├── README.md               # This file
└── workspace/
    ├── CAPABILITIES.md     # Full reference documentation
    ├── skills/
    │   ├── config-validate/SKILL.md
    │   └── cost-report/SKILL.md
    ├── scripts/
    │   └── validate-skills.sh
    ├── agents/
    │   ├── researcher/IDENTITY.md
    │   ├── coder/IDENTITY.md
    │   └── reviewer/IDENTITY.md
    └── .claude/commands/
        └── openclaw-status.md
```

## Manual Steps

After running `install.sh`, apply these patches manually:

1. **AGENTS.md** - See `agents-patch.md` for content to add
2. **TOOLS.md** - See `tools-patch.md` for content to add

## Verification

```bash
# Check config applied
jq '.agents.defaults.subagents.maxConcurrent' ~/.openclaw/openclaw.json
# Expected: 4

# Validate skills
~/.openclaw/workspace/scripts/validate-skills.sh

# Test via agent
# Ask Forge: "validate config"
# Ask Forge: "cost report"
```

## Rollback

```bash
# Restore config from backup
cp ~/.openclaw/openclaw.json.backup.* ~/.openclaw/openclaw.json
systemctl --user restart openclaw-gateway

# Remove installed files
rm -rf ~/.openclaw/workspace/skills/config-validate
rm -rf ~/.openclaw/workspace/skills/cost-report
rm -rf ~/.openclaw/workspace/agents/{researcher,coder,reviewer}
rm ~/.openclaw/workspace/scripts/validate-skills.sh
rm ~/.openclaw/workspace/CAPABILITIES.md
```

## Source Analysis

Based on:
- `Openclaw_analysis/openclaw-analysis-report.md` (Claude Code)
- `Openclaw_analysis/codex-implementation-analysis.md` (Codex)
- `Openclaw_analysis/gemini-architecture-analysis.md` (Gemini)

## Deferred (Needs Upstream PR)

These issues require changes to OpenClaw source code:
- Environment variable leak in skill execution (try/finally wrapper)
- Spawn pre-check for concurrency limits
- Skill name logging to stdout (subsystem logger)
- Skills validate CLI command
