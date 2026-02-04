---
name: cost-report
description: Generate cost and usage report from OpenClaw diagnostics
triggers:
  - "cost report"
  - "usage report"
  - "token usage"
  - "api costs"
---

# Cost Report Skill

Generates usage and cost estimates from OpenClaw diagnostic data.

## Data Sources

### 1. Gateway Logs
```bash
# Count API calls by provider from today's log
LOG="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"
if [ -f "$LOG" ]; then
  echo "=== Today's API Activity ==="
  grep -o 'provider"*:*"*[a-zA-Z-]*' "$LOG" 2>/dev/null | sort | uniq -c | sort -rn | head -10
fi
```

### 2. Session Token Counts
```bash
# Estimate tokens from session files
echo "=== Session Sizes (proxy for token usage) ==="
ls -lhS ~/.openclaw/agents/main/sessions/*.jsonl 2>/dev/null | head -5
```

### 3. Model Usage Distribution
```bash
# Extract model usage from logs
LOG="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"
if [ -f "$LOG" ]; then
  echo "=== Model Usage ==="
  grep -oE '(claude-opus|claude-sonnet|kimi-k2|qwen|deepseek|llama)[^"]*' "$LOG" 2>/dev/null | sort | uniq -c | sort -rn | head -10
fi
```

## Cost Estimation

### Anthropic Models (per 1M tokens)
| Model | Input | Output |
|-------|-------|--------|
| claude-opus-4-5 | $15.00 | $75.00 |
| claude-sonnet-4 | $3.00 | $15.00 |

### Free Tier Models
- Kimi K2.5 (Nvidia): Free tier
- DeepSeek V3.2 (Featherless): Free tier
- Qwen3 235B (Featherless): Free tier

## Report Format

Generate summary with:
1. Total API calls today
2. Model distribution
3. Estimated costs (Anthropic only)
4. Recommendations for cost optimization

## Optimization Tips

- Route simple queries to Kimi K2.5 (free)
- Use subagent model hierarchy (Kimi → DeepSeek → Opus)
- Enable caching to reduce redundant calls
