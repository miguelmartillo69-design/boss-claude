# TOOLS.md Patch

Add this section **before** the "## What Goes Here" section:

```markdown
## Custom Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| **config-validate** | "validate config" | Check openclaw.json for errors |
| **cost-report** | "cost report" | Generate usage and cost estimates |

### Skill Validation Script
\`\`\`bash
~/.openclaw/workspace/scripts/validate-skills.sh [skill-name]
\`\`\`

Validates SKILL.md frontmatter, dependencies, and configuration.

---
```
