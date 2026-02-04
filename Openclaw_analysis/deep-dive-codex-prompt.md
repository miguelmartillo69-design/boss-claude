# Codex Implementation Analysis: OpenClaw

You are analyzing the OpenClaw codebase as an **implementation specialist**. Focus on concrete code patterns, execution flow, and specific improvement opportunities.

## Repository

**Path**: `/home/claw/.npm-global/lib/node_modules/openclaw/`
**Version**: 2026.2.2-3
**Type**: Personal AI Assistant Platform (TypeScript/Node.js, compiled to dist/)

## Baseline Scan

- **Source**: dist/ contains compiled JavaScript
- **Extensions**: 34 channel integrations (telegram, discord, slack, whatsapp, signal, etc.)
- **Skills**: 55 built-in skills
- **Key files**: model-selection-*.js, extensionAPI.js, manager-*.js, plugin-sdk/

## Analysis Tasks

### 1. Agent System

Search for agent configuration and spawning:
- Find files with "agent" in name or containing agent logic
- Document how agents are defined (schema, required fields)
- Find how agents are instantiated and invoked
- Map the agent lifecycle: creation → execution → cleanup
- Find the subagent spawning mechanism (sessions_spawn)

**Key files to examine**:
- dist/plugin-sdk/agent-scope-*.js
- dist/register.subclis-*.js
- dist/configure-*.js
- dist/manager-*.js

### 2. Skill System

Map the skill implementation:
- How are skills registered? (check qmd-manager, manifest-registry)
- What interface must skills implement?
- How does an agent invoke a skill?
- How are skill results returned?
- Error handling patterns

**Key files**:
- dist/qmd-manager-*.js
- dist/manifest-registry-*.js
- skills/ directory structure
- dist/exec-approvals-*.js

### 3. LLM Integration

Trace all LLM touchpoints:
- Where are LLM clients initialized?
- Model selection logic (model-selection-*.js)
- Prompt construction patterns
- Response handling and streaming
- Token counting, rate limiting, fallback logic

**Key files**:
- dist/model-selection-*.js
- dist/plugin-sdk/model-selection-*.js
- dist/plugin-sdk/pi-model-discovery-*.js

### 4. Configuration

Identify configuration patterns:
- openclaw.json structure analysis
- How config is loaded and validated
- Environment variable usage
- Hardcoded values that should be configurable

## Output Format

Save your complete analysis to: `/home/claw/.openclaw/workspace/docs/codex-implementation-analysis.md`

Structure as:

```markdown
# Codex Implementation Analysis: OpenClaw

## Executive Summary
[2-3 sentences on overall findings]

## 1. Agent System
### Agent Definition Schema
### Agent Instantiation
### Agent Lifecycle
### Subagent Spawning
[Specific file:line references]

## 2. Skill System
### Skill Registration
### Skill Interface
### Execution Flow
### Error Handling
[Specific file:line references]

## 3. LLM Integration
### Client Setup
### Model Selection
### Prompt Construction
### Response Handling
### Operational Concerns
[Specific file:line references]

## 4. Configuration
### Config Files
### Schema/Validation
### Environment Variables
### Hardcoded Values
[Specific file:line references]

## 5. Priority Issues
| Issue | Location | Impact | Suggested Fix |
|-------|----------|--------|---------------|

## 6. Quick Wins
[Small changes with high impact]
```

## Important

1. Reference actual file paths and line numbers
2. Include relevant code snippets as evidence
3. Be specific (not "add validation" but "add X validation in file Y")
4. Focus on implementation details, not theory
5. The source is compiled JS - look for patterns despite obfuscation
