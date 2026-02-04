# Codex Implementation Analysis: OpenClaw

## Executive Summary
OpenClaw’s agent runtime is a layered flow: agent config is normalized and resolved via `agent-scope`, then runs are executed with model fallback and a provider-specific embedded runner that handles auth profiles, context guards, and error/failover logic. Skills are first-class artifacts parsed from `SKILL.md` frontmatter, then filtered and surfaced both in system prompts and as user-invocable commands; skill execution can either dispatch to tools or rewrite the prompt for the LLM to invoke. Configuration loading is strict (Zod + plugin schema validation), with JSON5 parsing, include resolution, and environment-variable hydration.

## 1. Agent System
### Agent Definition Schema
OpenClaw’s agent schema is defined in the config Zod schema. Each agent entry supports identity, workspace, model overrides, skills list, subagent config, tools/sandbox policies, and memory search overrides.

File: `dist/config-Ces-J9_M.js:2460`
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
  humanDelay: HumanDelaySchema.optional(),
  heartbeat: HeartbeatSchema,
  identity: IdentitySchema,
  groupChat: GroupChatSchema,
  subagents: z.object({
    allowAgents: z.array(z.string()).optional(),
    model: z.union([z.string(), z.object({ primary: z.string().optional(), fallbacks: z.array(z.string()).optional() }).strict()]).optional(),
    thinking: z.string().optional()
  }).strict().optional(),
  sandbox: AgentSandboxSchema,
  tools: AgentToolsSchema
}).strict();
```

Agents are wired into the top-level schema via `agents.defaults` and `agents.list`.

File: `dist/config-Ces-J9_M.js:2685`
```js
const AgentsSchema = z.object({
  defaults: z.lazy(() => AgentDefaultsSchema).optional(),
  list: z.array(AgentEntrySchema).optional()
}).strict().optional();
```

### Agent Instantiation
Agent selection and normalization happen in `agent-scope`, including default agent selection and per-agent config resolution. This is the core mapping that every run uses to find workspace and agentDir.

File: `dist/agent-scope-jm0ZdXwM.js:447`
```js
function listAgentIds(cfg) { /* ... */ }
function resolveDefaultAgentId(cfg) { /* ... */ }
function resolveAgentConfig(cfg, agentId) {
  const entry = resolveAgentEntry(cfg, normalizeAgentId(agentId));
  if (!entry) return;
  return {
    name: typeof entry.name === "string" ? entry.name : void 0,
    workspace: typeof entry.workspace === "string" ? entry.workspace : void 0,
    agentDir: typeof entry.agentDir === "string" ? entry.agentDir : void 0,
    model: typeof entry.model === "string" || entry.model && typeof entry.model === "object" ? entry.model : void 0,
    skills: Array.isArray(entry.skills) ? entry.skills : void 0,
    /* ... */
  };
}
function resolveAgentWorkspaceDir(cfg, agentId) { /* ... */ }
function resolveAgentDir(cfg, agentId) { /* ... */ }
```

### Agent Lifecycle
The runtime flow lives in `agent` command execution: resolve thinking defaults, run with model fallback, execute either CLI or embedded agent, emit lifecycle events, update session store, and deliver results.

File: `dist/agent-CzlfEeEi.js:535`
```js
const sessionFile = resolveSessionFilePath(sessionId, sessionEntry, { agentId: sessionAgentId });
const startedAt = Date.now();
let lifecycleEnded = false;
let result;
let fallbackProvider = provider;
let fallbackModel = model;
try {
  const runContext = resolveAgentRunContext(opts);
  const messageChannel = resolveMessageChannel(runContext.messageChannel, opts.replyChannel ?? opts.channel);
  const spawnedBy = opts.spawnedBy ?? sessionEntry?.spawnedBy;
  const fallbackResult = await runWithModelFallback({
    cfg,
    provider,
    model,
    agentDir,
    fallbacksOverride: resolveAgentModelFallbacksOverride(cfg, sessionAgentId),
    run: (providerOverride, modelOverride) => {
      if (isCliProvider(providerOverride, cfg)) {
        return runCliAgent({ /* ... */ });
      }
      return runEmbeddedPiAgent({ /* ... */ });
    }
  });
  result = fallbackResult.result;
  fallbackProvider = fallbackResult.provider;
  fallbackModel = fallbackResult.model;
  if (!lifecycleEnded) emitAgentEvent({ stream: "lifecycle", data: { phase: "end", startedAt, endedAt: Date.now(), aborted: result.meta.aborted ?? false } });
} catch (err) {
  if (!lifecycleEnded) emitAgentEvent({ stream: "lifecycle", data: { phase: "error", startedAt, endedAt: Date.now(), error: String(err) } });
  throw err;
}
if (sessionStore && sessionKey) await updateSessionStoreAfterAgentRun({ /* ... */ });
return await deliverAgentCommandResult({ /* ... */ });
```

### Subagent Spawning
Subagent spawning is implemented as the `sessions_spawn` tool. It validates requester context, enforces allowlists, creates a subagent session key, optionally patches model selection, then dispatches an agent run via the gateway and registers the subagent run for callbacks.

File: `dist/extensionAPI.js:33778`
```js
const SessionsSpawnToolSchema = Type.Object({
  task: Type.String(),
  label: Type.Optional(Type.String()),
  agentId: Type.Optional(Type.String()),
  model: Type.Optional(Type.String()),
  thinking: Type.Optional(Type.String()),
  runTimeoutSeconds: Type.Optional(Type.Number({ minimum: 0 })),
  timeoutSeconds: Type.Optional(Type.Number({ minimum: 0 })),
  cleanup: optionalStringEnum(["delete", "keep"])
});

if (typeof requesterSessionKey === "string" && isSubagentSessionKey(requesterSessionKey)) return jsonResult({
  status: "forbidden",
  error: "sessions_spawn is not allowed from sub-agent sessions"
});

const targetAgentId = requestedAgentId ? normalizeAgentId(requestedAgentId) : requesterAgentId;
if (targetAgentId !== requesterAgentId) {
  const allowAgents = resolveAgentConfig(cfg, requesterAgentId)?.subagents?.allowAgents ?? [];
  /* ... allowlist enforcement ... */
}
const childSessionKey = `agent:${targetAgentId}:subagent:${crypto.randomUUID()}`;

await callGateway({ method: "agent", params: { message: task, sessionKey: childSessionKey, lane: AGENT_LANE_SUBAGENT, extraSystemPrompt: childSystemPrompt, spawnedBy: spawnedByKey } });
registerSubagentRun({ runId: childRunId, childSessionKey, requesterSessionKey: requesterInternalKey, /* ... */ });
```

A subagent-specific bootstrap allowlist is enforced at file-injection time to keep subagent contexts minimal.

File: `dist/agent-scope-jm0ZdXwM.js:433`
```js
const SUBAGENT_BOOTSTRAP_ALLOWLIST = new Set([DEFAULT_AGENTS_FILENAME, DEFAULT_TOOLS_FILENAME]);
function filterBootstrapFilesForSession(files, sessionKey) {
  if (!sessionKey || !isSubagentSessionKey(sessionKey)) return files;
  return files.filter((file) => SUBAGENT_BOOTSTRAP_ALLOWLIST.has(file.name));
}
```

## 2. Skill System
### Skill Registration
Skill discovery merges multiple sources (extra, bundled, managed, workspace, plus plugin-defined skill dirs). Each skill gets frontmatter parsed and metadata/flags resolved.

File: `dist/plugin-sdk/pi-embedded-helpers-BmJlO1jG.js:4533`
```js
function loadSkillEntries(workspaceDir, opts) {
  const managedSkillsDir = opts?.managedSkillsDir ?? path.join(CONFIG_DIR, "skills");
  const workspaceSkillsDir = path.join(workspaceDir, "skills");
  const bundledSkillsDir = opts?.bundledSkillsDir ?? resolveBundledSkillsDir();
  const extraDirs = (opts?.config?.skills?.load?.extraDirs ?? []).map((d) => typeof d === "string" ? d.trim() : "").filter(Boolean);
  const pluginSkillDirs = resolvePluginSkillDirs({ workspaceDir, config: opts?.config });
  const mergedExtraDirs = [...extraDirs, ...pluginSkillDirs];
  /* ... load bundled/extra/managed/workspace and merge by skill name ... */
  return Array.from(merged.values()).map((skill) => {
    let frontmatter = {};
    try { frontmatter = parseFrontmatter(fs.readFileSync(skill.filePath, "utf-8")); } catch {}
    return { skill, frontmatter, metadata: resolveOpenClawMetadata(frontmatter), invocation: resolveSkillInvocationPolicy(frontmatter) };
  });
}
```

Plugin manifests can also contribute skills, and registry loading is cached to avoid repeated scans.

File: `dist/manifest-registry-BFpLJJDB.js:595`
```js
function loadPluginManifestRegistry(params) {
  const normalized = normalizePluginsConfig((params.config ?? {}).plugins);
  const cacheKey = buildCacheKey({ workspaceDir: params.workspaceDir, plugins: normalized });
  /* ... cache ... */
  const discovery = params.candidates ? { candidates: params.candidates, diagnostics: params.diagnostics ?? [] } : discoverOpenClawPlugins({ workspaceDir: params.workspaceDir, extraPaths: normalized.loadPaths });
  /* ... load manifests, build records ... */
  return { plugins: records, diagnostics };
}
```

### Skill Interface
Skill behavior is controlled by SKILL.md frontmatter. The parser supports OpenClaw-specific `metadata` JSON, `requires` (bins/env/config), `install` specs, and invocation flags (user-invocable, disable-model-invocation).

File: `dist/plugin-sdk/pi-embedded-helpers-BmJlO1jG.js:4138`
```js
function resolveOpenClawMetadata(frontmatter) {
  const raw = getFrontmatterValue(frontmatter, "metadata");
  /* ... parse JSON5 ... */
  return {
    always: typeof metadataObj.always === "boolean" ? metadataObj.always : void 0,
    emoji: typeof metadataObj.emoji === "string" ? metadataObj.emoji : void 0,
    homepage: typeof metadataObj.homepage === "string" ? metadataObj.homepage : void 0,
    skillKey: typeof metadataObj.skillKey === "string" ? metadataObj.skillKey : void 0,
    primaryEnv: typeof metadataObj.primaryEnv === "string" ? metadataObj.primaryEnv : void 0,
    os: osRaw.length > 0 ? osRaw : void 0,
    requires: requiresRaw ? { bins: normalizeStringList(requiresRaw.bins), anyBins: normalizeStringList(requiresRaw.anyBins), env: normalizeStringList(requiresRaw.env), config: normalizeStringList(requiresRaw.config) } : void 0,
    install: install.length > 0 ? install : void 0
  };
}
function resolveSkillInvocationPolicy(frontmatter) {
  return {
    userInvocable: parseFrontmatterBool(getFrontmatterValue(frontmatter, "user-invocable"), true),
    disableModelInvocation: parseFrontmatterBool(getFrontmatterValue(frontmatter, "disable-model-invocation"), false)
  };
}
```

Eligibility gating includes per-skill enable flags, OS/platform filtering, bin/env/config requirements, and allowlist gating for bundled skills.

File: `dist/plugin-sdk/pi-embedded-helpers-BmJlO1jG.js:4291`
```js
function shouldIncludeSkill(params) {
  const skillConfig = resolveSkillConfig(config, resolveSkillKey(entry.skill, entry));
  const allowBundled = normalizeAllowlist(config?.skills?.allowBundled);
  const osList = entry.metadata?.os ?? [];
  const remotePlatforms = eligibility?.remote?.platforms ?? [];
  if (skillConfig?.enabled === false) return false;
  if (!isBundledSkillAllowed(entry, allowBundled)) return false;
  if (osList.length > 0 && !osList.includes(resolveRuntimePlatform()) && !remotePlatforms.some((platform) => osList.includes(platform))) return false;
  /* ... bins/env/config requirements ... */
  return true;
}
```

### Execution Flow
Skill snapshots and command definitions are built per workspace. Skills are exposed as `/skill` or per-skill commands; invocations can dispatch to tools or rewrite the prompt to instruct the LLM to use a specific skill.

File: `dist/plugin-sdk/pi-embedded-helpers-BmJlO1jG.js:4585`
```js
function buildWorkspaceSkillSnapshot(workspaceDir, opts) {
  const eligible = filterSkillEntries(opts?.entries ?? loadSkillEntries(workspaceDir, opts), opts?.config, opts?.skillFilter, opts?.eligibility);
  const resolvedSkills = eligible.filter((entry) => entry.invocation?.disableModelInvocation !== true).map((entry) => entry.skill);
  return {
    prompt: [opts?.eligibility?.remote?.note?.trim(), formatSkillsForPrompt(resolvedSkills)].filter(Boolean).join("\n"),
    skills: eligible.map((entry) => ({ name: entry.skill.name, primaryEnv: entry.metadata?.primaryEnv })),
    resolvedSkills,
    version: opts?.snapshotVersion
  };
}
```

File: `dist/plugin-sdk/index.js:26755`
```js
function listSkillCommandsForWorkspace(params) {
  return buildWorkspaceSkillCommandSpecs(params.workspaceDir, {
    config: params.cfg,
    skillFilter: params.skillFilter,
    eligibility: { remote: getRemoteSkillEligibility() },
    reservedNames: resolveReservedCommandNames()
  });
}
function resolveSkillCommandInvocation(params) {
  const trimmed = params.commandBodyNormalized.trim();
  if (!trimmed.startsWith("/")) return null;
  /* ... /skill <name> [args] parsing ... */
}
```

File: `dist/plugin-sdk/index.js:62701`
```js
const skillInvocation = allowTextCommands && skillCommands.length > 0 ? resolveSkillCommandInvocation({
  commandBodyNormalized: command.commandBodyNormalized,
  skillCommands
}) : null;
if (skillInvocation) {
  if (dispatch?.kind === "tool") {
    const tool = createOpenClawTools({ /* ... */ }).find((candidate) => candidate.name === dispatch.toolName);
    if (!tool) return { kind: "reply", reply: { text: `❌ Tool not available: ${dispatch.toolName}` } };
    const text = extractTextFromToolResult(await tool.execute(toolCallId, { command: rawArgs, commandName: skillInvocation.command.name, skillName: skillInvocation.command.skillName })) ?? "✅ Done.";
    return { kind: "reply", reply: { text } };
  }
  const rewrittenBody = [`Use the "${skillInvocation.command.skillName}" skill for this request.`, /* ... */].join("\n\n");
  ctx.Body = rewrittenBody;
  sessionCtx.Body = rewrittenBody;
}
```

### Error Handling
Skill execution paths handle missing tools and tool execution errors with structured replies (e.g., “Tool not available” / execution exception). `QmdMemoryManager` similarly wraps external process failures and invalid JSON in explicit errors.

File: `dist/plugin-sdk/index.js:62737`
```js
if (!tool) {
  typing.cleanup();
  return { kind: "reply", reply: { text: `❌ Tool not available: ${dispatch.toolName}` } };
}
try {
  const text = extractTextFromToolResult(await tool.execute(/* ... */)) ?? "✅ Done.";
  return { kind: "reply", reply: { text } };
} catch (err) {
  const message = err instanceof Error ? err.message : String(err);
  return { kind: "reply", reply: { text: `❌ ${message}` } };
}
```

File: `dist/qmd-manager-BSCOmXYZ.js:200`
```js
async search(query, opts) {
  /* ... */
  try {
    stdout = (await this.runQmd(args, { timeoutMs: this.qmd.limits.timeoutMs })).stdout;
  } catch (err) {
    log.warn(`qmd query failed (${String(err)})`);
    throw err instanceof Error ? err : new Error(String(err));
  }
  /* ... JSON parse with error handling ... */
}
```

## 3. LLM Integration
### Client Setup
Embedded runs resolve model metadata, ensure model catalogs are present, enforce context-window guardrails, and resolve API keys via auth profiles (including GitHub Copilot token exchange).

File: `dist/loader-BrK9xPUo.js:28349`
```js
const provider = (params.provider ?? DEFAULT_PROVIDER).trim() || DEFAULT_PROVIDER;
const modelId = (params.model ?? DEFAULT_MODEL).trim() || DEFAULT_MODEL;
await ensureOpenClawModelsJson(params.config, agentDir);
const { model, error, authStorage, modelRegistry } = resolveModel$4(provider, modelId, agentDir, params.config);
if (!model) throw new Error(error ?? `Unknown model: ${provider}/${modelId}`);
const ctxGuard = evaluateContextWindowGuard({ /* ... */ });
if (ctxGuard.shouldBlock) throw new FailoverError(`Model context window too small (${ctxGuard.tokens} tokens). Minimum is ${CONTEXT_WINDOW_HARD_MIN_TOKENS}.`, { reason: "unknown", provider, model: modelId });

const authStore = ensureAuthProfileStore(agentDir, { allowKeychainPrompt: false });
const profileOrder = resolveAuthProfileOrder({ cfg: params.config, store: authStore, provider, preferredProfile: preferredProfileId });
/* ... applyApiKeyInfo() sets runtime API key, includes Copilot token exchange ... */
```

### Model Selection
Model fallback and provider cooldown handling are centralized in `runWithModelFallback`, which enumerates configured fallbacks, skips providers in cooldown, and records failover attempts.

File: `dist/loader-BrK9xPUo.js:9946`
```js
async function runWithModelFallback(params) {
  const candidates = resolveFallbackCandidates({ cfg: params.cfg, provider: params.provider, model: params.model, fallbacksOverride: params.fallbacksOverride });
  const authStore = params.cfg ? ensureAuthProfileStore(params.agentDir, { allowKeychainPrompt: false }) : null;
  for (let i = 0; i < candidates.length; i += 1) {
    const candidate = candidates[i];
    if (authStore) {
      const profileIds = resolveAuthProfileOrder({ cfg: params.cfg, store: authStore, provider: candidate.provider });
      const isAnyProfileAvailable = profileIds.some((id) => !isProfileInCooldown(authStore, id));
      if (profileIds.length > 0 && !isAnyProfileAvailable) { /* ... skip with rate_limit reason ... */ }
    }
    try { return { result: await params.run(candidate.provider, candidate.model), provider: candidate.provider, model: candidate.model, attempts }; }
    catch (err) { /* ... classify and record failover attempts ... */ }
  }
  throw new Error(`All models failed (...)`);
}
```

### Prompt Construction
The system prompt explicitly injects the available skills section (built from resolved skill entries) and tool inventory, and enforces a consistent skill-selection protocol.

File: `dist/plugin-sdk/index.js:34895`
```js
function buildSkillsSection(params) {
  if (params.isMinimal) return [];
  const trimmed = params.skillsPrompt?.trim();
  if (!trimmed) return [];
  return [
    "## Skills (mandatory)",
    "Before replying: scan <available_skills> <description> entries.",
    `- If exactly one skill clearly applies: read its SKILL.md at <location> with \`${params.readToolName}\`, then follow it.`,
    "- If multiple could apply: choose the most specific one, then read/follow it.",
    "- If none clearly apply: do not read any SKILL.md.",
    "Constraints: never read more than one skill up front; only read after selecting.",
    trimmed,
    ""
  ];
}
```

OpenAI-specific history sanitation prevents invalid reasoning blocks from breaking the Responses API.

File: `dist/pi-embedded-helpers-_HVJVM57.js:886`
```js
/**
* OpenAI Responses API can reject transcripts that contain a standalone `reasoning` item id
* without the required following item.
*/
function downgradeOpenAIReasoningBlocks(messages) { /* ... */ }
```

### Response Handling
The embedded runner handles prompt errors, context overflow (with auto-compaction retry), role-ordering issues, image-size errors, and failover logic (including auth-profile cooldowns and thinking-level fallback).

File: `dist/loader-BrK9xPUo.js:28547`
```js
if (promptError && !aborted) {
  const errorText = describeUnknownError(promptError);
  if (isContextOverflowError(errorText)) {
    if (!isCompactionFailure && !overflowCompactionAttempted) {
      const compactResult = await compactEmbeddedPiSessionDirect({ /* ... */ });
      if (compactResult.compacted) { /* retry */ }
    }
    return { payloads: [{ text: "Context overflow: prompt too large...", isError: true }], meta: { /* ... */ } };
  }
  if (/incorrect role information|roles must alternate/i.test(errorText)) return { payloads: [{ text: "Message ordering conflict...", isError: true }], meta: { /* ... */ } };
  const imageSizeError = parseImageSizeError(errorText);
  if (imageSizeError) return { payloads: [{ text: `Image too large...`, isError: true }], meta: { /* ... */ } };
  /* ... mark auth profile failure / fallback thinking / throw FailoverError ... */
}
```

### Operational Concerns
- Context window guardrails block unsafe model selections and emit warnings for low contexts. (See `evaluateContextWindowGuard` in `runEmbeddedPiAgent`.)
- Tool result formatting is channel-aware (markdown vs plain) and is set early in the embedded runner. (See `resolvedToolResultFormat` in `runEmbeddedPiAgent`.)

## 4. Configuration
### Config Files
`openclaw.json` (JSON5) is parsed with include resolution and schema validation. The schema includes extensive agent defaults, tools policy, and bindings.

File: `dist/config-Ces-J9_M.js:4525`
```js
function parseConfigJson5(raw, json5 = JSON5) {
  try { return { ok: true, parsed: json5.parse(raw) }; }
  catch (err) { return { ok: false, error: String(err) }; }
}
function createConfigIO(overrides = {}) {
  const configPath = /* ... resolve default config ... */;
  function loadConfig() {
    /* ... resolve includes, apply env vars, validate, apply defaults, normalize paths ... */
    const validated = validateConfigObjectWithPlugins(resolvedConfig);
    /* ... */
    return applyConfigOverrides(cfg);
  }
}
```

### Schema/Validation
Validation is Zod-based with legacy checks, duplicate `agentDir` detection, and plugin-schema validation. It returns explicit errors and warnings (with path + message).

File: `dist/config-Ces-J9_M.js:4221`
```js
function validateConfigObject(raw) {
  const legacyIssues = findLegacyConfigIssues(raw);
  const validated = OpenClawSchema.safeParse(raw);
  if (!validated.success) return { ok: false, issues: /* ... */ };
  const duplicates = findDuplicateAgentDirs(validated.data);
  if (duplicates.length > 0) return { ok: false, issues: [{ path: "agents.list", message: formatDuplicateAgentDirError(duplicates) }] };
  const avatarIssues = validateIdentityAvatar(validated.data);
  if (avatarIssues.length > 0) return { ok: false, issues: avatarIssues };
  return { ok: true, config: applyModelDefaults(applyAgentDefaults(applySessionDefaults(validated.data))) };
}
```

File: `dist/config-Ces-J9_M.js:4259`
```js
function validateConfigObjectWithPlugins(raw) {
  const base = validateConfigObject(raw);
  /* ... loadPluginManifestRegistry(), validate plugin ids, config schema, channels, heartbeat targets ... */
  if (issues.length > 0) return { ok: false, issues, warnings };
  return { ok: true, config, warnings };
}
```

### Environment Variables
Config IO hydrates environment variables from config and optionally reads shell profiles for known keys. A fixed list of expected keys is used for shell env fallback.

File: `dist/config-Ces-J9_M.js:4437`
```js
const SHELL_ENV_EXPECTED_KEYS = [
  "OPENAI_API_KEY",
  "ANTHROPIC_API_KEY",
  "ANTHROPIC_OAUTH_TOKEN",
  "GEMINI_API_KEY",
  "ZAI_API_KEY",
  "OPENROUTER_API_KEY",
  "AI_GATEWAY_API_KEY",
  "MINIMAX_API_KEY",
  "SYNTHETIC_API_KEY",
  "ELEVENLABS_API_KEY",
  "TELEGRAM_BOT_TOKEN",
  "DISCORD_BOT_TOKEN",
  "SLACK_BOT_TOKEN",
  "SLACK_APP_TOKEN",
  "OPENCLAW_GATEWAY_TOKEN",
  "OPENCLAW_GATEWAY_PASSWORD"
];
```

### Hardcoded Values
Model aliases and defaults are hardcoded in config defaults and used to resolve shorthand names into provider/model identifiers.

File: `dist/config-Ces-J9_M.js:145`
```js
const DEFAULT_MODEL_ALIASES = {
  opus: "anthropic/claude-opus-4-5",
  sonnet: "anthropic/claude-sonnet-4-5",
  gpt: "openai/gpt-5.2",
  "gpt-mini": "openai/gpt-5-mini",
  gemini: "google/gemini-3-pro-preview",
  "gemini-flash": "google/gemini-3-flash-preview"
};
```

## 5. Priority Issues
| Issue | Location | Impact | Suggested Fix |
|-------|----------|--------|---------------|
| Skill env overrides mutate global `process.env` and rely on caller cleanup | `dist/plugin-sdk/pi-embedded-helpers-BmJlO1jG.js:4327` | If a run crashes before cleanup, env vars can leak into subsequent runs, causing cross-skill credential bleed or incorrect gating | Apply env overrides per-skill execution by spawning child processes with explicit `env` maps or encapsulate overrides in a try/finally wrapper at the callsite so cleanup is guaranteed |
| `sessions_spawn` does not enforce `subagents.maxConcurrent` at tool entry | `dist/extensionAPI.js:33778` + schema in `dist/config-Ces-J9_M.js:2649` | Subagents can be spawned beyond configured concurrency if upstream throttling doesn’t catch it, risking runaway resource usage | Add a guard in `sessions_spawn` to check current subagent count vs `agents.defaults.subagents.maxConcurrent` (and per-agent overrides) and return a structured “busy” response |
| Skill filtering logs to stdout on every filter apply | `dist/plugin-sdk/pi-embedded-helpers-BmJlO1jG.js:4500` | Noisy logs in production and can leak skill names into stdout in hosted environments | Replace `console.log` with subsystem logger gated by debug flag; include a once-per-session throttle |

## 6. Quick Wins
- Add a lightweight `skills.validate` command to report missing bins/env/config requirements using `shouldIncludeSkill` (centralized logic already exists). Source: `dist/plugin-sdk/pi-embedded-helpers-BmJlO1jG.js:4291`.
- Surface plugin registry diagnostics directly in `openclaw status` output using the data from `loadPluginManifestRegistry` to reduce “why isn’t my skill/plugin loaded?” support loops. Source: `dist/manifest-registry-BFpLJJDB.js:595`.
- Emit a one-line warning when a skill command rewrites the prompt (e.g., for `/skill <name>`) so operators can distinguish skill dispatch vs. LLM-directed skill usage. Source: `dist/plugin-sdk/index.js:62765`.
