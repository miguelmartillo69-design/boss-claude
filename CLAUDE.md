# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This directory (`/home/claw/Claude`) is the **Claude Code CLI working directory** within an OpenClaw multi-agent orchestration platform installation (v2026.2.2-3) running on WSL2 Linux. It's not a code project to build or test, but rather a workspace for Claude Code CLI sessions.

### Mission Statement

**My primary function is to help configure and optimize the OpenClaw installation. I aim to know OpenClaw better than it knows itself.**

This means:
- Deep understanding of OpenClaw architecture (source code, configuration, runtime behavior)
- Proactive optimization of models, costs, and performance
- Troubleshooting and debugging gateway/agent issues
- Creating custom automations, hooks, and workflows
- Maintaining comprehensive documentation
- Analyzing and improving the OpenClaw codebase

## System Architecture

### OpenClaw Platform
OpenClaw is a multi-agent AI orchestration platform that provides:
- **Gateway Service**: HTTP API server (port 18789, localhost-only) for agent communication
- **Multi-channel Support**: Telegram bot (@pimpshizzleBot), CLI interface via Claude Code
- **Agent Management**: Concurrent agent execution (max 4 agents, 8 subagents)
- **Memory System**: File-based persistence with daily notes and long-term memory
- **Model Integration**: Multiple AI providers (Anthropic, Moonshot, Nvidia, Featherless, Perplexity)

### Directory Structure

```
/home/claw/
├── Claude/                    # This directory - Claude Code CLI workspace
│   ├── claude-code-templates/ # Production-ready agents, commands, skills, workflows
│   │   └── .claude/           # Template components (symlinked to ~/.claude/)
│   ├── .claude/               # Claude CLI configuration and data (GLOBAL)
│   │   ├── commands/          # 7 commands (symlinked from templates)
│   │   ├── agents/            # 8 agents (symlinked from templates)
│   │   ├── skills/            # 5 skills including fork-terminal
│   │   ├── workflows/         # 4 workflows
│   │   ├── utils/             # Utility modules (symlinked)
│   │   ├── plugins/           # Installed plugins (11 total)
│   │   ├── projects/          # Project workspaces
│   │   ├── settings.json      # Plugin configuration with hooks
│   │   └── history.jsonl      # Command history
│   ├── .claude.json           # User account and session data
│   └── CLAUDE.md              # This file
│
├── .openclaw/                 # OpenClaw core installation
│   ├── openclaw.json          # Main configuration (models, agents, channels, gateway)
│   ├── identity/              # Device identity and Ed25519 authentication keys
│   ├── agents/main/           # Primary agent configuration
│   │   ├── agent/             # models.json, auth-profiles.json
│   │   └── sessions/          # Session storage
│   ├── workspace/             # Agent personality and memory system
│   │   ├── SOUL.md            # Core personality ("Forge" - project manager/co-founder)
│   │   ├── AGENTS.md          # Workspace guidelines for agents
│   │   ├── IDENTITY.md        # Agent identity template
│   │   ├── USER.md            # Human user profile (Mike)
│   │   ├── TOOLS.md           # Local environment notes
│   │   ├── HEARTBEAT.md       # Periodic task configuration
│   │   ├── CLAUDE-CODE-SETUP.md # Claude Code capabilities for OpenClaw admin
│   │   ├── memory/            # Daily notes (YYYY-MM-DD.md format)
│   │   ├── projects/          # Project-specific workspaces (biomedical, music)
│   │   ├── skills/            # Custom skills and scripts
│   │   ├── docs/              # Architecture documentation
│   │   ├── config/            # Additional configuration
│   │   └── .claude/           # Claude Code custom components (OpenClaw-specific)
│   │       ├── agents/        # openclaw-troubleshooter.md
│   │       ├── commands/      # openclaw-status.md, openclaw-prime.md
│   │       └── hooks/         # Custom workflow hooks
│   ├── devices/               # Paired device management
│   ├── credentials/           # Secure credential storage
│   ├── logs/                  # Application logs
│   └── cron/                  # Scheduled jobs
│
└── .npm-global/               # Global npm packages
    └── lib/node_modules/openclaw/ # OpenClaw source code (TypeScript)
        ├── dist/              # Compiled source
        ├── docs/              # Documentation (28 directories)
        ├── extensions/        # Extension modules (34 directories)
        ├── skills/            # Built-in skills (55 directories)
        ├── README.md          # Main documentation
        └── package.json       # Dependencies and metadata
```

## Key Services

### OpenClaw Gateway
- **Command**: `systemctl --user [start|stop|restart|status] openclaw-gateway`
- **Port**: 18789 (localhost only, token auth)
- **Logs**: `/tmp/openclaw/openclaw-YYYY-MM-DD.log` or `journalctl --user -u openclaw-gateway -f`
- **Config**: `~/.openclaw/openclaw.json`

### CLI Tools
```bash
# OpenClaw CLI
openclaw --version              # Check version (2026.2.2-3)
openclaw doctor                 # Run diagnostics

# View gateway logs
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log

# Check listening ports
ss -tlnp | grep -E '18789|18792'
```

## Configuration Files

| File | Purpose |
|------|---------|
| `~/.openclaw/openclaw.json` | Main OpenClaw config: models, agents, channels, gateway settings, API keys |
| `~/.openclaw/agents/main/agent/models.json` | Model provider settings |
| `~/.openclaw/agents/main/agent/auth-profiles.json` | API authentication profiles |
| `~/.openclaw/workspace/SOUL.md` | Agent personality definition ("Forge") |
| `~/.openclaw/workspace/AGENTS.md` | Workspace guidelines for all agents |
| `~/.claude/settings.json` | Claude CLI plugin config and hooks |
| `~/.claude.json` | Claude CLI user account data |

## AI Models Configured

### Primary Models
- **Anthropic Claude Opus 4.5** - Default primary model
- **Google Antigravity Claude Opus 4.5 Thinking** - Fallback

### Alternative Models
- **Moonshot Kimi K2.5** - 256K context window (via Nvidia/Featherless)
- **Moonshot Kimi K2 Thinking** - Reasoning model
- **Qwen3 235B** - Via Featherless
- **Llama 4 Maverick** - Via Featherless
- **DeepSeek V3.2** - Via Featherless
- **Perplexity Sonar/Sonar Pro** - Web-enhanced models

### Subagents Configuration
Subagents default to Kimi K2.5 to optimize costs while maintaining quality.

## Claude Code Plugins

### Installed from Official Marketplace (11 plugins)

**Code Intelligence & Analysis:**
1. **typescript-lsp** - TypeScript/JavaScript language server for OpenClaw source code
2. **pyright-lsp** - Python language server for scripts and tools
3. **serena** - Semantic code analysis and intelligent understanding

**Codebase Understanding:**
4. **greptile** - AI-powered natural language codebase search
   - Query: "How does OpenClaw handle sub-agent spawning?"
5. **claude-code-setup** - Analyze codebases and recommend tailored automations

**Code Quality & Review:**
6. **code-review** - Automated code review with specialized agents
7. **code-simplifier** - Code refinement for clarity and maintainability

**Documentation & Workflow:**
8. **claude-md-management** - Maintain CLAUDE.md and workspace documentation
9. **hookify** - Create custom hooks for OpenClaw-specific workflows
10. **security-guidance** - Security reminder hooks for sensitive operations

**Integration:**
11. **github** - Repository management for OpenClaw development

### Previously Installed (Local)
- **playwright** - Browser automation capabilities
- **superpowers** - Extended capabilities and workflows
- **plugin-dev** - Plugin development tools

### Official Plugin Marketplace
Configured: `anthropics/claude-plugins-official` (46+ plugins available)
- Install: `claude plugin install <plugin-name>`
- List: `claude plugin list`
- Update: `claude plugin marketplace update`

## Claude Code Templates Integration

**Repository**: `/home/claw/Claude/claude-code-templates/`
**Installation**: Global (symlinked to `~/.claude/`)

### Available Components

**Commands (7):**
- `/prime` - Load current working directory context
- `/quick-prime` - Fast context summary
- `/deep-prime` - Deep analysis of specific areas
- `/onboarding` - Understand codebase structure
- `/code-review` - Quality review
- `/rca` - Root cause analysis
- `/all_skills` - List available skills

**Agents (8):**
- `codebase-analyst` - Pattern discovery and architecture analysis
- `code-reviewer` - Code quality review
- `debugger` - Systematic troubleshooting
- `test-automator` - Testing workflows
- `context-manager` - Session management
- `technical-researcher` - Research integrations
- `library-researcher` - Library exploration
- `deployment-engineer` - Infrastructure management

**Skills (5):**
- `lsp-symbol-navigation` - Navigate code with LSP
- `lsp-dependency-analysis` - Analyze dependencies
- `lsp-type-safety-check` - Type checking
- `fork-terminal` - Spawn parallel terminal sessions (xterm configured)
- `agent-browser` - Agent browsing capabilities

**Workflows (4):**
- `feature-development` - Feature implementation workflow
- `bug-investigation` - Bug fixing workflow
- `code-quality` - Quality improvement workflow
- `new-developer` - Developer onboarding workflow

### Fork-Terminal Capability

**Status**: ✅ Fully operational (xterm installed, X server working)

**Usage:**
```bash
# Spawn parallel Claude Code session
"Fork terminal use claude code to analyze the gateway architecture"

# Run with different model
"Fork terminal with codex to generate test fixtures"

# Include session context
"Fork terminal use claude code to implement feature X, include summary of work so far"
```

**Supported Tools:**
- Claude Code (opus, sonnet, haiku models)
- Codex CLI (GPT-5.2)
- Gemini CLI (rate-limited currently)
- Raw CLI commands

## Custom OpenClaw Components

### Commands
- **`/openclaw-status`** - Quick health check (gateway, channels, memory, errors, skills, sessions)
- **`/openclaw-prime`** - Load OpenClaw context (SOUL.md, AGENTS.md, USER.md, memory, projects)

### Agents
- **`openclaw-troubleshooter`** - OpenClaw-specific debugging specialist
  - Gateway architecture expert
  - Multi-channel communication analysis
  - Agent session management
  - Memory persistence debugging
  - Configuration validation

### Documentation
- **`CLAUDE-CODE-SETUP.md`** - Comprehensive capabilities guide
  - Plugin reference and use cases
  - Installation maps (source, config, workspaces)
  - Workflow examples
  - Integration patterns
  - Next steps roadmap

## Hooks

### User Prompt Submit Hook
Located in `~/.claude/settings.json`, automatically checks if prompt mentions "openclaw" and reminds to check `/mnt/c/Users/Claw/openclaw-faq.md` first.

## Agent Personality ("Forge")

The OpenClaw agent is named "Forge" with these characteristics:
- Role: Project manager / technical co-founder / systems thinker
- Style: Direct, practical, opinionated, no fluff
- Focus: Execution over theory, resourceful problem-solving
- Boundaries: Private things stay private, careful with external actions
- Memory: File-based persistence in `~/.openclaw/workspace/memory/`

## User Account

- **Email**: mike5150@protonmail.ch
- **Role**: Admin
- **Subscription**: Max tier (5x rate limit)
- **Device ID**: Paired and approved with operator.admin scope

## Concurrency Limits

- Max concurrent agents: 4
- Max concurrent subagents: 8
- Compaction mode: safeguard
- Context pruning: cache-ttl with 1h TTL

## Security Notes

- Gateway binds to localhost only (no external exposure)
- Token-based gateway authentication
- Device authentication via Ed25519 key pair
- API keys stored in `openclaw.json` and auth-profiles (treat as sensitive)
- No external database dependencies (all file-based storage)

## Common Issues

### Gateway Won't Start
1. Check Node.js: `node --version` (expect v22.x)
2. Check service: `systemctl --user status openclaw-gateway`
3. View logs: `journalctl --user -u openclaw-gateway -f`

### Telegram Bot Conflicts
409 errors indicate another bot instance is running. Ensure only one gateway instance is active:
```bash
systemctl --user restart openclaw-gateway
```

### Port Already in Use
```bash
ss -tlnp | grep 18789
# Kill conflicting process if needed
```

## OpenClaw Source Code Access

### Location
**Path**: `/home/claw/.npm-global/lib/node_modules/openclaw/`

### Structure
- **dist/** - Compiled TypeScript source (full codebase)
- **docs/** - 28 documentation directories
- **extensions/** - 34 extension modules
- **skills/** - 55 built-in skills
- **README.md** - Comprehensive documentation
- **CHANGELOG.md** - Version history

### Code Intelligence
- **TypeScript LSP** provides full IntelliSense for OpenClaw source
- **Greptile** enables natural language queries: "Find session spawning logic"
- **Serena** provides semantic code analysis and understanding
- Direct file system access to all OpenClaw source code

## Claude Code Capabilities for OpenClaw Administration

### Deep Analysis
- Query codebase with natural language (greptile)
- Navigate OpenClaw source with IntelliSense (TypeScript LSP)
- Semantic code analysis (serena)
- Pattern discovery (codebase-analyst agent)

### Troubleshooting
- `/openclaw-status` - System health check
- `/rca` - Root cause analysis
- `openclaw-troubleshooter` agent - Specialized debugging
- `debugger` agent - Systematic problem solving

### Configuration & Optimization
- Analyze openclaw.json and suggest improvements
- Optimize model hierarchy for cost/performance
- Review sub-agent configuration
- Validate API keys and authentication

### Documentation & Maintenance
- Maintain workspace documentation (claude-md-management)
- Capture session learnings into memory files
- Update architecture documentation
- Keep project knowledge current

### Automation & Workflow
- Create custom hooks (hookify)
- Build specialized skills for common operations
- Set up automated code review
- Configure security reminders

### Parallel Execution
- Fork terminal for independent tasks
- Run multiple Claude Code sessions simultaneously
- Use different models (opus, sonnet, haiku, codex)
- Background long-running operations

## Important Notes

- This directory is a **workspace**, not a code project to build or test
- The actual OpenClaw platform code is installed via npm in `~/.npm-global/`
- Agent memory persists in `~/.openclaw/workspace/memory/` as markdown files
- Configuration changes should be made to `~/.openclaw/openclaw.json`
- Log files rotate daily in `/tmp/openclaw/`
- **Mission**: Know OpenClaw better than it knows itself 🔧

## Working with OpenClaw

### Collaboration Pattern: Claude Code + Forge

**Claude Code (me):**
- Development and administration tool
- Direct file system access
- Plugin ecosystem integration
- IDE-style code intelligence
- Fork-terminal for parallel sessions

**Forge (OpenClaw agent):**
- Main orchestrator via gateway
- Uses `sessions_spawn()` for sub-agents
- Interacts via Telegram (@Forge70bot)
- Maintains MEMORY.md and daily notes

**Shared Workspace:**
- Both access `/home/claw/.openclaw/workspace/`
- Documentation and memory files synchronized
- Complementary capabilities (runtime vs. development)

### Quick Reference Commands

**OpenClaw Management:**
```bash
systemctl --user status openclaw-gateway      # Check gateway
openclaw doctor                                # Run diagnostics
openclaw --version                             # Check version
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log  # View logs
```

**Claude Code Analysis:**
```bash
/openclaw-prime                                # Load OpenClaw context
/openclaw-status                               # Health check
/onboarding                                    # Understand codebase
/rca "issue description"                       # Root cause analysis
/deep-prime "area" "topic"                     # Deep dive
```

**Plugin Management:**
```bash
claude plugin list                             # List installed
claude plugin install <name>                   # Install plugin
claude plugin marketplace list                 # List marketplaces
claude plugin marketplace update               # Update marketplace
```

**Greptile Queries:**
```
"Use greptile to find all session spawning code"
"Query codebase: how does gateway handle authentication?"
"Find files related to sub-agent management"
```

### Session Workflow

When working in this environment:
1. **Start with context**: `/openclaw-prime` to load SOUL.md, AGENTS.md, USER.md, memory
2. **Check system health**: `/openclaw-status` for gateway, channels, errors
3. **Understand codebase**: Use greptile, TypeScript LSP, `/onboarding` for deep understanding
4. **Review memory**: Check `~/.openclaw/workspace/memory/` for recent activity
5. **Consult documentation**: `/mnt/c/Users/Claw/openclaw-faq.md` for OpenClaw-specific questions
6. **Respect personality**: Be direct, practical, and opinionated (Forge's style)
7. **Update workspace**: Capture learnings in memory files and documentation
8. **Verify changes**: `/openclaw-status` after configuration changes

### Reference Documentation

- **Main Guide**: `/home/claw/.openclaw/workspace/CLAUDE-CODE-SETUP.md`
- **Architecture**: `/home/claw/.openclaw/workspace/docs/SUBAGENT-ARCHITECTURE.md`
- **Runbook**: `/home/claw/.openclaw/workspace/docs/RUNBOOK.md`
- **OpenClaw Source**: `/home/claw/.npm-global/lib/node_modules/openclaw/README.md`
- **This File**: `/home/claw/Claude/CLAUDE.md`

---

**Mission**: Know OpenClaw better than it knows itself 🔧
**Updated**: 2026-02-04 02:00 PST
