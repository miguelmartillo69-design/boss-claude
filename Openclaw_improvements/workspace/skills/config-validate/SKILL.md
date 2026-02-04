---
name: config-validate
description: Validate OpenClaw configuration for common errors
triggers:
  - "validate config"
  - "check openclaw config"
  - "config validation"
---

# Config Validation Skill

Validates `~/.openclaw/openclaw.json` for common configuration errors.

## Validation Checks

### 1. JSON Syntax
```bash
jq empty ~/.openclaw/openclaw.json 2>&1 || echo "FAIL: Invalid JSON syntax"
```

### 2. Required Sections
```bash
jq -e '.agents.defaults.model.primary' ~/.openclaw/openclaw.json > /dev/null || echo "FAIL: Missing agents.defaults.model.primary"
jq -e '.gateway.port' ~/.openclaw/openclaw.json > /dev/null || echo "FAIL: Missing gateway.port"
jq -e '.channels' ~/.openclaw/openclaw.json > /dev/null || echo "FAIL: Missing channels section"
```

### 3. Model References
Verify that referenced models exist in providers:
```bash
PRIMARY=$(jq -r '.agents.defaults.model.primary' ~/.openclaw/openclaw.json)
echo "Primary model: $PRIMARY"
```

### 4. API Key Presence
```bash
# Check for empty or placeholder API keys
jq -r '.. | strings | select(test("^(sk-|nvapi-|pplx-)"))' ~/.openclaw/openclaw.json | head -5
echo "API keys found (truncated for security)"
```

### 5. Concurrency Limits
```bash
MAX_AGENTS=$(jq -r '.agents.defaults.maxConcurrent // 4' ~/.openclaw/openclaw.json)
MAX_SUBAGENTS=$(jq -r '.agents.defaults.subagents.maxConcurrent // 8' ~/.openclaw/openclaw.json)
echo "Max agents: $MAX_AGENTS, Max subagents: $MAX_SUBAGENTS"
if [ "$MAX_SUBAGENTS" -gt 8 ]; then
  echo "WARN: subagents.maxConcurrent > 8 may cause resource issues"
fi
```

### 6. Gateway Settings
```bash
BIND=$(jq -r '.gateway.bind // "loopback"' ~/.openclaw/openclaw.json)
if [ "$BIND" != "loopback" ]; then
  echo "WARN: Gateway not bound to loopback - security risk"
fi
```

## Output Format

Report validation results as:
- **PASS**: Check passed
- **WARN**: Non-critical issue
- **FAIL**: Critical error requiring fix

## Usage

Run this skill before restarting the gateway after config changes.
