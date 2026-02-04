# Codebase Analysis Report: OpenClaw

**Analysis Date:** 2026-02-04
**Version Analyzed:** 2026.2.2-3
**Analysis Method:** Claude Code deep analysis with Codex/Gemini parallel terminals (in progress)

---

## Executive Summary

- **Architecture**: OpenClaw is a well-designed local-first personal AI assistant with a clean separation between Gateway (control plane), Pi agent runtime (execution), and channel extensions (messaging)
- **Strengths**: Excellent multi-model support, comprehensive channel coverage (13+ platforms), robust skill system, and thoughtful security defaults
- **Key Opportunity**: The subagent system could benefit from more sophisticated orchestration patterns (currently task-based delegation without inter-agent communication)
- **Configuration**: Well-structured `openclaw.json` with good model fallback chains; could benefit from schema validation
- **Recommended Focus**: Optimize subagent model costs, enhance skill composability, and add configuration validation

---

## Synthesis Notes

This analysis synthesizes findings from:
1. Direct source code examination of compiled JavaScript in `dist/`
2. Runtime configuration analysis (`openclaw.json`)
3. Skill system examination (55 built-in skills)
4. Extension architecture review (34 channel integrations)

---

## 1. Agent System Improvements

### Current Architecture

**Paradigm**: Task-based delegation with session isolation

OpenClaw uses a **single primary agent** pattern with **subagent spawning** for parallelization:

```
Primary Agent (main session)
    └── sessions_spawn() → Subagent 1 (isolated session)
    └── sessions_spawn() → Subagent 2 (isolated session)
    └── sessions_spawn() → ...up to maxConcurrent: 8
```

**Key Source Files:**
- `dist/agent-scope-*.js` - Agent ID resolution, session key parsing
- `dist/sandbox-*.js` - Tool groups and profiles
- `dist/tool-display-*.js` - Tool definitions including `sessions_spawn`

**Session Key Format:**
```
agent:{agentId}:{sessionType}
agent:main:subagent:{task-id}
```

**Agent Configuration Location:**
```
~/.openclaw/agents/{agentId}/
    agent/models.json
    agent/auth-profiles.json
    sessions/
```

### Strengths

1. **Clean session isolation** - Each subagent gets its own context
2. **Model override per subagent** - Can specify different models for different tasks
3. **Concurrent execution** - Up to 8 subagents in parallel
4. **Timeout management** - `runTimeoutSeconds` prevents runaway agents

### Weaknesses

1. **No inter-agent communication** - Subagents can't directly message each other
2. **No planning/reflection loops** - Pure task execution without self-review
3. **Limited state sharing** - Results must flow through parent agent
4. **No agent roles** - All agents are generic; no specialist definitions

### Recommended Agent Template

```yaml
# OpenClaw Agent Configuration Schema
# Location: ~/.openclaw/agents/{agentId}/agent/config.yaml

agent:
  id: string                          # Unique identifier (a-z, 0-9, hyphens)

  # Model Configuration
  model:
    primary: string                   # e.g., "anthropic/claude-opus-4-5"
    fallbacks:                        # Ordered fallback list
      - string

  # Subagent Settings (when this agent spawns children)
  subagents:
    maxConcurrent: 8                  # Max parallel subagents
    model:
      primary: string                 # Default: cheaper model for subtasks
      fallbacks: [string]

  # Workspace Integration
  workspace: string                   # Path to workspace files (SOUL.md, etc.)

  # Memory Settings
  memory:
    enabled: true
    search:
      provider: string                # "openai" | "local"

  # Context Management
  contextPruning:
    mode: string                      # "cache-ttl" | "none"
    ttl: string                       # e.g., "1h"

  compaction:
    mode: string                      # "safeguard" | "aggressive"

  # Behavioral Settings
  heartbeat:
    every: string                     # e.g., "30m"

  # Tool Access (optional restriction)
  tools:
    allow: [string]                   # Whitelist
    deny: [string]                    # Blacklist
    profile: string                   # Predefined: "minimal" | "standard" | "full"

  # Skills Filter (optional)
  skills: [string]                    # Limit to specific skills
```

### Industry Comparison

| Framework | Agent Model | OpenClaw Position |
|-----------|-------------|-------------------|
| AutoGPT | Autonomous goal-driven | OpenClaw is more controlled/delegated |
| CrewAI | Role-based collaborative | OpenClaw lacks explicit roles |
| LangGraph | Stateful graph workflows | OpenClaw is simpler but less flexible |
| OpenAI Assistants | Tool-using conversational | Most similar to OpenClaw approach |

### Recommendations

1. **Add Agent Roles**: Define specialist agent configurations (researcher, coder, reviewer)
2. **Implement ReAct Loop**: Add reflection step between tool uses
3. **Enable Inter-agent Communication**: Add message passing for complex workflows
4. **Add Planning Phase**: For complex tasks, generate plan before execution

---

## 2. Skill System Improvements

### Current Architecture

**Skill Definition**: Markdown-based with YAML frontmatter

```markdown
---
name: skill-name
description: What this skill does
metadata:
  openclaw:
    emoji: "🎯"
    requires:
      bins: ["curl"]              # Required binaries
      anyBins: ["claude", "codex"] # Any of these
---

# Skill Name

Usage instructions and examples...
```

**Skill Sources:**
1. **Bundled**: `~/.npm-global/lib/node_modules/openclaw/skills/` (55 skills)
2. **Managed**: Installed via `openclaw skills install`
3. **Workspace**: `~/.openclaw/workspace/skills/`

**Key Source Files:**
- `dist/qmd-manager-*.js` - Skill loading and management
- `dist/manifest-registry-*.js` - Skill registration
- `dist/skills-cli-*.js` - CLI skill commands

### Skill Categories (55 bundled)

| Category | Skills |
|----------|--------|
| **Productivity** | 1password, apple-notes, apple-reminders, bear-notes, notion, obsidian, trello, things-mac |
| **Communication** | discord, slack, imsg |
| **AI/Coding** | coding-agent, gemini, skill-creator |
| **Media** | camsnap, video-frames, openai-image-gen, openai-whisper(-api), sag, sherpa-onnx-tts, spotify-player, songsee |
| **Utilities** | weather, github, healthcheck, summarize, session-logs, model-usage |
| **System** | tmux, canvas, clawhub |

### Strengths

1. **Simple definition format** - Markdown is easy to write
2. **Flexible metadata** - Can specify dependencies, emoji, hints
3. **Multiple sources** - Bundled, managed, workspace
4. **Auto-discovery** - Skills are detected by directory structure

### Weaknesses

1. **No schema validation** - YAML frontmatter isn't validated
2. **Limited composability** - Skills can't easily call other skills
3. **No versioning** - No way to pin skill versions
4. **Weak error contract** - No standardized error reporting

### Skill Development Guide

```markdown
# How to Add a New OpenClaw Skill

## 1. Create Skill Directory

Location: `~/.openclaw/workspace/skills/my-skill/`

## 2. Create SKILL.md

```markdown
---
name: my-skill
description: Brief description of what this skill does
metadata:
  openclaw:
    emoji: "🎯"
    requires:
      bins: ["required-binary"]     # Must have all
      anyBins: ["option-a", "option-b"]  # Must have at least one
---

# My Skill

## Overview
What this skill enables the agent to do.

## Prerequisites
- Required software
- Required API keys

## Usage

### Basic Command
\`\`\`bash
command example
\`\`\`

### Common Patterns
Show typical usage patterns with examples.

## Troubleshooting
Common issues and solutions.
```

## 3. Test the Skill

```bash
# Verify skill is detected
openclaw skills list

# Test in conversation
"Use my-skill to do X"
```

## 4. Optional: Add Configuration

If your skill needs configuration in `openclaw.json`:

```json
{
  "skills": {
    "entries": {
      "my-skill": {
        "apiKey": "..."
      }
    }
  }
}
```

## Best Practices

1. **Single responsibility** - One skill, one purpose
2. **Clear examples** - Show exact commands
3. **Error handling** - Document failure modes
4. **Minimal dependencies** - Only require what's needed
```

### Industry Comparison

| Framework | Tool Model | OpenClaw Position |
|-----------|------------|-------------------|
| LangChain Tools | Function-based with schemas | OpenClaw is more flexible but less type-safe |
| OpenAI Function Calling | JSON schema required | OpenClaw has no schema validation |
| MCP | Standardized protocol | OpenClaw could adopt MCP patterns |
| Semantic Kernel | Strongly-typed plugins | OpenClaw is more dynamic |

### Recommendations

1. **Add JSON Schema Validation**: Validate YAML frontmatter on load
2. **Standardize Error Contract**: Define error response format
3. **Enable Skill Chaining**: Allow skills to invoke other skills
4. **Add Versioning**: Support skill version pinning

---

## 3. LLM Integration Improvements

### Current Architecture

**Model Resolution Flow:**
```
1. Check agent-specific override (agents.list[id].model)
2. Check defaults (agents.defaults.model.primary)
3. Apply fallbacks (agents.defaults.model.fallbacks)
4. Use DEFAULT_MODEL ("claude-opus-4-5") if none configured
```

**Key Source Files:**
- `dist/model-selection-*.js` - Model resolution, aliases, fallbacks
- `dist/auth-profiles-*.js` - API key and OAuth management

**Provider Support:**
- Native: `anthropic`, `openai`
- OAuth: `google-antigravity`, `qwen-portal`, `minimax-portal`
- OpenAI-compatible: `nvidia`, `featherless`, `perplexity`, `venice`, `synthetic`

### Current Model Configuration

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-opus-4-5",
        "fallbacks": ["google-antigravity/claude-opus-4-5-thinking"]
      },
      "subagents": {
        "model": {
          "primary": "nvidia/moonshotai/kimi-k2.5",
          "fallbacks": [
            "featherless/moonshotai/Kimi-K2.5",
            "featherless/deepseek-ai/DeepSeek-V3.2",
            "nvidia/moonshotai/kimi-k2-thinking"
          ]
        }
      }
    }
  }
}
```

### Model Selection Matrix

| Task Type | Primary Model | Fallback | Rationale |
|-----------|---------------|----------|-----------|
| **Complex reasoning** | claude-opus-4-5 | claude-opus-4-5-thinking | Best chain-of-thought |
| **Code generation** | claude-opus-4-5 | kimi-k2.5 | Superior code quality |
| **Subagent tasks** | kimi-k2.5 | deepseek-v3.2 | Cost-effective for subtasks |
| **Web search integration** | sonar-pro | sonar | Real-time web access |
| **Long context (>128K)** | claude-opus-4-5 | kimi-k2.5 (256K) | Context window limits |
| **Thinking/reasoning** | kimi-k2-thinking | opus-4-5-thinking | Extended reasoning |

### Context Length Routing

| Context Size | Recommended Model | Notes |
|--------------|-------------------|-------|
| < 32K tokens | kimi-k2.5 | Cost efficient |
| 32K - 128K | claude-opus-4-5 | Quality + context |
| > 128K | kimi-k2.5 (256K window) | Only option for very long |

### Cost Optimization

| Priority | Strategy |
|----------|----------|
| **Minimize cost** | Use kimi-k2.5 as primary, only escalate on failure |
| **Balance** | Use opus for main agent, kimi for subagents (current config) |
| **Maximize quality** | Use opus everywhere with thinking fallbacks |

### Strengths

1. **Flexible fallback chains** - Graceful degradation
2. **Multi-provider support** - Not locked to one vendor
3. **Alias system** - Human-friendly model names
4. **OAuth support** - Use existing subscriptions

### Weaknesses

1. **No task-based routing** - Same model for all task types
2. **No cost tracking per task** - Hard to optimize
3. **No automatic quality/cost tradeoff** - Manual configuration only
4. **No token estimation** - Can't predict context overflow

### Recommendations

1. **Add Task-Based Model Router**:
```javascript
function selectModel(taskType, complexity, contextLength) {
  if (taskType === "code" && complexity === "high")
    return "anthropic/claude-opus-4-5";
  if (contextLength > 100000)
    return "nvidia/moonshotai/kimi-k2.5";
  if (taskType === "simple")
    return "featherless/deepseek-ai/DeepSeek-V3.2";
  // ...
}
```

2. **Add Token Estimation**: Pre-flight check before sending to avoid context overflow

3. **Implement Cost Tracking**: Log model usage and costs per session

4. **Add Quality Feedback Loop**: Track task success rates per model

---

## 4. Configuration Improvements

### Current Structure

**Main Config**: `~/.openclaw/openclaw.json`

```json
{
  "meta": { "lastTouchedVersion": "...", "lastTouchedAt": "..." },
  "env": { "vars": { /* API keys */ } },
  "auth": { "profiles": { /* OAuth and API key profiles */ } },
  "models": { "providers": { /* Custom providers */ } },
  "agents": { "defaults": { /* Agent configuration */ } },
  "tools": { /* Tool-specific config */ },
  "channels": { /* Channel configurations */ },
  "gateway": { /* Gateway settings */ },
  "skills": { /* Skill configurations */ },
  "hooks": { /* Internal hooks */ },
  "plugins": { /* Plugin enablement */ }
}
```

### Strengths

1. **Single file** - Easy to backup and version
2. **Logical grouping** - Clear section organization
3. **Sensible defaults** - Works out of box
4. **Migration support** - `doctor` command fixes issues

### Issues Identified

#### Issue 1: No Schema Validation

**Current:** Config loaded without validation; typos silently ignored

**Recommended:** Add JSON schema or Zod validation

```json
// Add to OpenClaw: schemas/openclaw-config.schema.json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["gateway"],
  "properties": {
    "gateway": {
      "type": "object",
      "required": ["port"],
      "properties": {
        "port": { "type": "integer", "minimum": 1024, "maximum": 65535 }
      }
    }
  }
}
```

#### Issue 2: Secrets in Main Config

**Current:** API keys stored alongside regular config

**After:**
```bash
# Split sensitive data
~/.openclaw/
  openclaw.json       # Non-sensitive config
  credentials/
    api-keys.json     # Sensitive (600 permissions)
```

#### Issue 3: No Environment-Specific Overrides

**Current:** Single config for all environments

**After:**
```
~/.openclaw/
  openclaw.json           # Base config
  openclaw.local.json     # Local overrides (gitignored)
  openclaw.dev.json       # Development overrides
```

### Before/After Examples

#### Model Configuration

**Before:**
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-opus-4-5"
      }
    }
  }
}
```

**After (with task routing):**
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-opus-4-5",
        "routing": {
          "byTaskType": {
            "code": "anthropic/claude-opus-4-5",
            "simple": "nvidia/moonshotai/kimi-k2.5",
            "search": "perplexity/sonar-pro"
          },
          "byContextLength": {
            "over128k": "nvidia/moonshotai/kimi-k2.5"
          }
        }
      }
    }
  }
}
```

---

## 5. Implementation Roadmap

### Phase 1: Quick Wins (< 2 hours each)

- [ ] **Add config validation on startup** - Use Zod to validate openclaw.json
  - File: Create `src/config/schema.ts`
  - Impact: Catch typos early, better error messages

- [ ] **Document all skill YAML frontmatter fields** - Create SKILL_SCHEMA.md
  - File: `docs/SKILL_SCHEMA.md`
  - Impact: Easier skill development

- [ ] **Add token estimation before requests** - Warn on potential overflow
  - File: `src/agents/context-estimator.ts`
  - Impact: Prevent failed requests

- [ ] **Create model cost tracking** - Log usage per session
  - File: `src/agents/cost-tracker.ts`
  - Impact: Enable cost optimization

### Phase 2: Core Improvements (2-8 hours each)

- [ ] **Implement task-based model routing**
  - Dependencies: Cost tracking (Phase 1)
  - Impact: Automatic cost/quality optimization

- [ ] **Add skill schema validation**
  - Dependencies: None
  - Impact: Better skill error messages

- [ ] **Create agent role definitions**
  - Dependencies: None
  - Impact: Enable specialist agents

- [ ] **Standardize skill error contract**
  - Dependencies: Skill schema validation
  - Impact: Better error handling

### Phase 3: Strategic Enhancements (1-3 days each)

- [ ] **Add inter-agent communication**
  - Requires: Agent role definitions
  - Impact: Enable complex multi-agent workflows

- [ ] **Implement ReAct reasoning loop**
  - Requires: None
  - Impact: Better complex task handling

- [ ] **Add skill composability**
  - Requires: Standardized error contract
  - Impact: Enable skill chaining

### Phase 4: Future Considerations

- [ ] **MCP protocol adoption** - Standardize tool interface
- [ ] **Planning agent pattern** - Generate plans before execution
- [ ] **Quality feedback loop** - Track success rates, auto-adjust models
- [ ] **Skill marketplace** - Community skill sharing

---

## 6. Appendices

### Appendix A: Tool Groups Reference

From `dist/sandbox-*.js`:

```javascript
const TOOL_GROUPS = {
  "group:sessions": ["sessions_spawn", "session_status"],
  "group:ui": ["browser", "canvas"],
  "group:automation": ["cron", "gateway"],
  "group:messaging": ["message"],
  "group:nodes": ["nodes"],
  "group:openclaw": [
    "browser", "canvas", "nodes", "cron", "gateway",
    "sessions_spawn", "session_status", "memory_search",
    "memory_get", "web_search", "web_fetch", "image"
  ]
};

const TOOL_PROFILES = {
  minimal: { allow: ["session_status"] },
  standard: { /* broader access */ },
  full: { /* all tools */ }
};
```

### Appendix B: Key File Locations

| Purpose | Path |
|---------|------|
| Main config | `~/.openclaw/openclaw.json` |
| Agent workspace | `~/.openclaw/workspace/` |
| Agent sessions | `~/.openclaw/agents/{id}/sessions/` |
| Skills (bundled) | `~/.npm-global/lib/node_modules/openclaw/skills/` |
| Skills (workspace) | `~/.openclaw/workspace/skills/` |
| Extensions | `~/.npm-global/lib/node_modules/openclaw/extensions/` |
| Plugin SDK | `~/.npm-global/lib/node_modules/openclaw/dist/plugin-sdk/` |
| Logs | `/tmp/openclaw/openclaw-YYYY-MM-DD.log` |

### Appendix C: Session Key Patterns

```
agent:main                              # Primary session
agent:main:subagent:task-123           # Subagent session
agent:forge:telegram:123456            # Channel-specific session
agent:main:acp:request-id              # ACP mode session
agent:main:thread:topic-id             # Thread session
```

### Appendix D: Model Reference Formats

```
provider/model-id                       # Full reference
anthropic/claude-opus-4-5               # Anthropic
nvidia/moonshotai/kimi-k2.5            # NVIDIA API
featherless/deepseek-ai/DeepSeek-V3.2  # Featherless
perplexity/sonar-pro                   # Perplexity
google-antigravity/claude-opus-4-5-thinking  # Google Antigravity
```

---

## Notes

This analysis was performed by examining the compiled JavaScript source in `dist/`, runtime configuration files, skill definitions, and extension structure. The codebase is well-organized despite being compiled/bundled. Key architectural patterns are clearly visible and the design shows thoughtful consideration of multi-model, multi-channel personal assistant requirements.

The primary recommendation is to enhance the agent coordination patterns to enable more sophisticated multi-agent workflows while maintaining the current simplicity for basic use cases.

---

## Appendix E: Codex Implementation Analysis (Full)

<details>
<summary>Click to expand Codex analysis (gpt-5.2-codex)</summary>

### Executive Summary
OpenClaw's agent runtime is a layered flow: agent config is normalized and resolved via `agent-scope`, then runs are executed with model fallback and a provider-specific embedded runner that handles auth profiles, context guards, and error/failover logic. Skills are first-class artifacts parsed from `SKILL.md` frontmatter, then filtered and surfaced both in system prompts and as user-invocable commands; skill execution can either dispatch to tools or rewrite the prompt for the LLM to invoke. Configuration loading is strict (Zod + plugin schema validation), with JSON5 parsing, include resolution, and environment-variable hydration.

### Key Findings

**Agent Schema** (`dist/config-Ces-J9_M.js:2460`):
```js
const AgentEntrySchema = z.object({
  id: z.string(),
  default: z.boolean().optional(),
  name: z.string().optional(),
  workspace: z.string().optional(),
  agentDir: z.string().optional(),
  model: AgentModelSchema.optional(),
  skills: z.array(z.string()).optional(),
  memorySearch: MemorySearchSchema,
  subagents: z.object({
    allowAgents: z.array(z.string()).optional(),
    model: z.union([z.string(), z.object({ primary: z.string().optional(), fallbacks: z.array(z.string()).optional() }).strict()]).optional(),
    thinking: z.string().optional()
  }).strict().optional(),
  sandbox: AgentSandboxSchema,
  tools: AgentToolsSchema
}).strict();
```

**Subagent Spawning** (`dist/extensionAPI.js:33778`):
```js
const SessionsSpawnToolSchema = Type.Object({
  task: Type.String(),
  label: Type.Optional(Type.String()),
  agentId: Type.Optional(Type.String()),
  model: Type.Optional(Type.String()),
  thinking: Type.Optional(Type.String()),
  runTimeoutSeconds: Type.Optional(Type.Number({ minimum: 0 })),
  cleanup: optionalStringEnum(["delete", "keep"])
});
```

**Skill Loading** (`dist/plugin-sdk/pi-embedded-helpers-BmJlO1jG.js:4533`):
- 5 sources merged: bundled, managed, workspace, extra, plugin-defined
- Frontmatter parsed for metadata, requires, invocation flags

**Model Fallback** (`dist/loader-BrK9xPUo.js:9946`):
```js
async function runWithModelFallback(params) {
  const candidates = resolveFallbackCandidates({ cfg, provider, model, fallbacksOverride });
  for (let i = 0; i < candidates.length; i += 1) {
    // Check auth profile cooldown, try run, record failover attempts
  }
}
```

**Config Validation** (`dist/config-Ces-J9_M.js:4221`):
- Zod-based with legacy checks
- Duplicate agentDir detection
- Plugin schema validation

### Priority Issues

| Issue | Location | Impact |
|-------|----------|--------|
| Skill env overrides can leak on crash | `pi-embedded-helpers:4327` | Cross-skill credential bleed |
| sessions_spawn doesn't enforce maxConcurrent | `extensionAPI.js:33778` | Runaway resource usage |
| Skill filtering logs to stdout | `pi-embedded-helpers:4500` | Noisy in production |

### Quick Wins
1. Add `skills.validate` command for missing requirements
2. Surface plugin diagnostics in `openclaw status`
3. Emit warning when skill command rewrites prompt

</details>

---

## Appendix F: Gemini Architecture Analysis (Full)

<details>
<summary>Click to expand Gemini analysis (gemini-2.5-flash)</summary>

### Executive Summary
OpenClaw demonstrates a sophisticated **hub-and-spoke agent architecture** built on the "Pi Agent Runtime". It distinguishes itself with a robust **event-driven reactive loop** that supports advanced deliberative features like "steering" (interrupts) and "follow-ups". The **Progressive Disclosure** skill framework is a standout architectural decision, prioritizing context window efficiency and cost optimization by loading resources only when needed.

### Agent Architecture

**Paradigm**: Reactive Loop with Deliberative Capabilities
- Core Loop: `agentLoop` in `@mariozechner/pi-agent-core` is event-driven
- Deliberative Features: `steeringQueue` (interrupts) + `followUpQueue` (post-task actions)
- State: `AgentState` with `thinkingLevel`, `steeringMode`, distinct message types

**Agent Boundaries**:
- Runtime vs Environment: Clear separation between brain (runtime) and body (extensions)
- Identity: File-based (`SOUL.md`, `BOOTSTRAP.md`) for flexible persona injection

**Multi-Agent Patterns**:
- Hub-and-Spoke: Runtime as hub, channels/tools as spokes
- Explicit Sub-agents: `llm-task` for JSON-based task delegation
- `open-prose` extension: "Programming language for agents" paradigm

### Industry Comparison

| Framework | Comparison |
|-----------|------------|
| AutoGPT | OpenClaw more engineered, typed event system |
| LangChain | Similar to AgentExecutor but with built-in "Steering" interrupts |
| MCP | Compatible but uses tight Pi Agent Runtime integration |

### Skill Framework

**Design Pattern**: Progressive Disclosure
- Load metadata → load body → load resources (only when needed)
- Superior to "load everything" approaches
- Best-in-class for context-constrained local agents

**Composability**:
- Modular: Self-contained `skills/<name>/` packages
- Resource-Oriented: `scripts/`, `references/`, `assets/` separation

### LLM Strategy

**Model Selection**:
- Primary + fallback chains in `openclaw.json`
- `pi-model-discovery` for dynamic model detection
- `llm-task` for task-specific model routing

**Context Management**:
- `transformContext` hook for custom pruning
- Entire Skill Framework designed around context efficiency

### Configuration Design

**Separation of Concerns**:
- Runtime: `openclaw.json` (global defaults)
- Extension: `openclaw.plugin.json` (plugin metadata)
- Skill: `SKILL.md` (self-contained definition)

**Validation**: Schema-first with JSON Schema for plugins/channels

**Extensibility**: Plugin SDK with strict contracts (`registerProvider`, `registerChannel`)

</details>

---

*Analysis completed by Claude Code (Opus 4.5) with parallel Codex (gpt-5.2-codex) and Gemini (gemini-2.5-flash) analysis*
