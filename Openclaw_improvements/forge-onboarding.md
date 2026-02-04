
## 🆕 Workspace Improvements (Auto-installed)

New capabilities have been added to your workspace. Review these when you have a moment.

### Agent Roles
You can now spawn specialized sub-agents with pre-configured models:

```javascript
sessions_spawn({ role: "researcher", task: "..." })  // Kimi K2.5 - research/web
sessions_spawn({ role: "coder", task: "..." })       // Claude Opus - implementation
sessions_spawn({ role: "reviewer", task: "..." })    // Kimi Thinking - code review
```

Role definitions: `workspace/agents/{role}/IDENTITY.md`

### New Skills
- **"validate config"** - Check openclaw.json for errors before restart
- **"cost report"** - Generate usage and cost estimates from logs

### Concurrency Limits
- Max subagents reduced to **4** (was 8) for stability
- Diagnostics enabled for cost tracking

### Reference
Full documentation: `workspace/CAPABILITIES.md`

---
