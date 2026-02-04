# CAPABILITIES.md - OpenClaw Improvements Reference

Last Updated: 2026-02-04

This document summarizes all improvements implemented from the OpenClaw analysis reports.

---

## Configuration Changes

### Concurrency Limits (Security)
- **subagents.maxConcurrent**: Reduced from 8 → 4
- **Reason**: Prevents resource exhaustion, mitigates concurrency bugs in spawn logic
- **Location**: `~/.openclaw/openclaw.json` → `agents.defaults.subagents.maxConcurrent`

### Diagnostics
- **diagnostics.enabled**: true
- **cacheTrace.enabled**: true
- **Purpose**: Enables cost tracking and performance monitoring

---

## Custom Skills

### config-validate
**Location**: `~/.openclaw/workspace/skills/config-validate/SKILL.md`

**Triggers**: "validate config", "check openclaw config"

**Checks**:
1. JSON syntax validity
2. Required sections (agents.defaults.model, gateway, channels)
3. API key presence
4. Concurrency limits (warns if subagents > 8)
5. Gateway security (warns if not bound to loopback)

**Usage**: Run before restarting gateway after config changes.

### cost-report
**Location**: `~/.openclaw/workspace/skills/cost-report/SKILL.md`

**Triggers**: "cost report", "usage report", "token usage"

**Data Sources**:
- Gateway logs (`/tmp/openclaw/openclaw-YYYY-MM-DD.log`)
- Session file sizes (proxy for token usage)
- Model usage distribution

**Cost Reference**:
| Model | Input/1M | Output/1M |
|-------|----------|-----------|
| claude-opus-4-5 | $15.00 | $75.00 |
| kimi-k2.5 | Free | Free |
| deepseek-v3.2 | Free | Free |

---

## Agent Roles

Pre-defined specialist agents with optimized model selection.

### researcher
**Model**: `nvidia/moonshotai/kimi-k2.5`
**Fallback**: `perplexity/sonar-pro`

**Best For**:
- Web research and information gathering
- Documentation analysis
- Comparative analysis
- Fact-checking

**Spawn**:
```javascript
sessions_spawn({ role: "researcher", task: "Research [topic]" })
```

### coder
**Model**: `anthropic/claude-opus-4-5`
**Fallback**: `nvidia/moonshotai/kimi-k2.5`

**Best For**:
- Code implementation
- Bug fixes
- Refactoring
- Test writing

**Spawn**:
```javascript
sessions_spawn({ role: "coder", task: "Implement [feature]" })
```

### reviewer
**Model**: `nvidia/moonshotai/kimi-k2-thinking`
**Fallback**: `anthropic/claude-opus-4-5`

**Best For**:
- Code review
- Security analysis
- Architecture review
- Documentation review

**Spawn**:
```javascript
sessions_spawn({ role: "reviewer", task: "Review [code/PR]" })
```

---

## Scripts & Tools

### validate-skills.sh
**Location**: `~/.openclaw/workspace/scripts/validate-skills.sh`

**Usage**:
```bash
./validate-skills.sh           # Validate all custom skills
./validate-skills.sh cost-report  # Validate specific skill
```

**Checks**:
- SKILL.md existence
- YAML frontmatter validity
- Required fields (name, description)
- Node dependencies (if applicable)

---

## Enhanced Commands

### /openclaw-status
**Location**: `~/.openclaw/workspace/.claude/commands/openclaw-status.md`

**Sections**:
1. Gateway service status
2. Port listening (18789, 18792)
3. Active channels
4. Memory & storage usage
5. Recent errors
6. Configuration summary (models, limits, settings)
7. Skills status (configured + custom)
8. Session activity
9. Agent roles
10. API activity (model usage today)

---

## Cost Optimization Strategy

### Model Routing Hierarchy

| Task Complexity | Primary Model | Cost |
|-----------------|---------------|------|
| Simple/Research | Kimi K2.5 | Free |
| Standard | DeepSeek V3.2 | Free |
| Complex/Code | Claude Opus | $15/$75 |

### Subagent Configuration
Subagents default to `nvidia/moonshotai/kimi-k2.5` with fallbacks:
1. `featherless/moonshotai/Kimi-K2.5`
2. `featherless/deepseek-ai/DeepSeek-V3.2`
3. `nvidia/moonshotai/kimi-k2-thinking`

### Estimated Savings
- **Before**: All tasks → Claude Opus
- **After**: Simple tasks → Free tier, Complex → Opus
- **Projected**: 50-70% cost reduction on API calls

---

## Security Notes

### Mitigated Issues

1. **Concurrency overflow**: Reduced maxConcurrent prevents spawn queue overflow
2. **Gateway binding**: Verified localhost-only (no external exposure)
3. **Token auth**: Gateway uses token authentication

### Known Issues (Upstream)

1. **Env variable leak**: Skills using env overrides may leak on crash (try/finally wrapper needed)
2. **Skill name logging**: Skill names logged to stdout (subsystem logger needed)
3. **Spawn pre-check**: No count validation before spawn acceptance

---

## Verification

### Quick Health Check
```bash
# Gateway status
systemctl --user status openclaw-gateway

# Run doctor
openclaw doctor

# Check config
jq '.agents.defaults.subagents.maxConcurrent' ~/.openclaw/openclaw.json
# Expected: 4
```

### Test Skills
```bash
# Validate skills
~/.openclaw/workspace/scripts/validate-skills.sh

# Test config validation (via agent)
"validate config"

# Test cost report (via agent)
"cost report"
```

---

## Rollback

If issues occur:

```bash
# Restore config backup
cp ~/.openclaw/openclaw.json.backup.20260204 ~/.openclaw/openclaw.json
systemctl --user restart openclaw-gateway

# Remove custom skills
rm -rf ~/.openclaw/workspace/skills/config-validate
rm -rf ~/.openclaw/workspace/skills/cost-report

# Remove scripts
rm ~/.openclaw/workspace/scripts/validate-skills.sh
```

---

## Source Analysis

These improvements are based on:
- `/home/claw/Claude/Openclaw_analysis/openclaw-analysis-report.md`
- `/home/claw/Claude/Openclaw_analysis/codex-implementation-analysis.md`
- `/home/claw/Claude/Openclaw_analysis/gemini-architecture-analysis.md`
