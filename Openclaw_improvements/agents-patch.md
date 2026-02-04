# AGENTS.md Patch

Add this section **before** the "## 🤖 Sub-Agent Guidelines" section:

```markdown
## 🎭 Agent Roles (Specialized Sub-Agents)

Pre-defined agent roles optimize for different tasks. Each has its own model preferences and personality.

### Available Roles

| Role | Model | Best For |
|------|-------|----------|
| **researcher** | Kimi K2.5 | Information gathering, web research, comparisons |
| **coder** | Claude Opus | Implementation, bug fixes, refactoring |
| **reviewer** | Kimi K2 Thinking | Code review, architecture review, QA |

### Spawn with Role

\`\`\`javascript
sessions_spawn({
  role: "researcher",
  task: "Research [topic] and summarize findings"
})

sessions_spawn({
  role: "coder",
  task: "Implement [feature] following existing patterns"
})

sessions_spawn({
  role: "reviewer",
  task: "Review [code/PR] for security and correctness"
})
\`\`\`

Role definitions live in `workspace/agents/{role}/IDENTITY.md`.

### Concurrency Limits

- **Max concurrent agents**: 4
- **Max concurrent subagents**: 4 (reduced from 8 for stability)

---
```
