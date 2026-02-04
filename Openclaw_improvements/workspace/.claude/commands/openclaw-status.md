---
name: openclaw-status
description: Comprehensive health check for OpenClaw system with diagnostics
user-invocable: true
---

# OpenClaw Status Check

## 1. Gateway Service
```bash
systemctl --user status openclaw-gateway --no-pager | head -10
```

## 2. Port Listening
```bash
ss -tlnp 2>/dev/null | grep -E '18789|18792' || echo "Gateway ports not listening"
```

## 3. Active Channels
```bash
tail -50 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log 2>/dev/null | grep -E "telegram|webchat|gateway" | tail -10
```

## 4. Memory & Storage
```bash
echo "=== Storage Usage ==="
du -sh /home/claw/.openclaw/ 2>/dev/null
echo ""
echo "=== Recent Memory Files ==="
ls -lht /home/claw/.openclaw/workspace/memory/ 2>/dev/null | head -5
```

## 5. Recent Errors
```bash
echo "=== Errors (last 100 lines) ==="
tail -100 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log 2>/dev/null | grep -i error | tail -10 || echo "No errors found"
```

## 6. Configuration Summary
```bash
echo "=== Config Summary ==="
jq '{
  primary_model: .agents.defaults.model.primary,
  max_agents: .agents.defaults.maxConcurrent,
  max_subagents: .agents.defaults.subagents.maxConcurrent,
  subagent_model: .agents.defaults.subagents.model.primary,
  gateway_port: .gateway.port,
  gateway_bind: .gateway.bind,
  telegram_enabled: .channels.telegram.enabled,
  diagnostics: .diagnostics.enabled
}' /home/claw/.openclaw/openclaw.json
```

## 7. Skills Status
```bash
echo "=== Configured Skills ==="
jq -r '.skills.entries | keys[]' /home/claw/.openclaw/openclaw.json 2>/dev/null
echo ""
echo "=== Custom Skills ==="
ls /home/claw/.openclaw/workspace/skills/ 2>/dev/null || echo "No custom skills"
```

## 8. Session Activity
```bash
echo "=== Active Sessions ==="
ls -lht /home/claw/.openclaw/agents/main/sessions/*.jsonl 2>/dev/null | grep -v deleted | head -5 || echo "No active sessions"
```

## 9. Agent Roles
```bash
echo "=== Defined Agent Roles ==="
ls -d /home/claw/.openclaw/workspace/agents/*/ 2>/dev/null | xargs -I{} basename {} || echo "No agent roles defined"
```

## 10. API Activity (Today)
```bash
LOG="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"
if [ -f "$LOG" ]; then
  echo "=== Model Usage Today ==="
  grep -oE '(claude-opus|claude-sonnet|kimi-k2|qwen|deepseek|llama)[^"]*' "$LOG" 2>/dev/null | sort | uniq -c | sort -rn | head -5 || echo "No model activity logged"
fi
```

Report findings in summary format:
- **OK**: System healthy
- **WARN**: Non-critical issues
- **FAIL**: Requires attention

Include recommendations for any issues found.
