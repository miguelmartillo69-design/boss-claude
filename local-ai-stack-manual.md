# Local AI Stack -- Owner's Manual

**System**: OpenClaw Local AI Infrastructure
**Version**: 1.0 (February 2026)
**Host**: WSL2 Linux, NVIDIA GPU (8GB VRAM)
**Compose Directory**: `/home/claw/Claude/self-hosted-ai-starter-kit/`

---

## Table of Contents

1. [Stack Overview](#1-stack-overview)
2. [Quick Start](#2-quick-start)
3. [Service Reference](#3-service-reference)
4. [Open WebUI API](#4-open-webui-api)
5. [n8n Workflow Automation](#5-n8n-workflow-automation)
6. [Ollama LLM Engine](#6-ollama-llm-engine)
7. [Qdrant Vector Database](#7-qdrant-vector-database)
8. [Integration Patterns](#8-integration-patterns)
9. [Automation Recipes](#9-automation-recipes)
10. [Security & Operations](#10-security--operations)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Stack Overview

Six Docker containers running on a single machine, connected via the `demo` network:

```
┌─────────────────────────────────────────────────────────────────┐
│  Host (WSL2 Linux)                                              │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ Open     │  │ n8n      │  │ Ollama   │  │ Qdrant   │       │
│  │ WebUI    │  │ Workflow  │  │ LLM      │  │ Vector   │       │
│  │ :3000    │  │ :5678    │  │ :11434   │  │ :6333    │       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘       │
│       │              │              │              │             │
│  ┌────┴──────────────┴──────────────┴──────────────┴─────┐      │
│  │                    Docker Network: demo                │      │
│  └────┬──────────────┬───────────────────────────────────┘      │
│       │              │                                          │
│  ┌────┴─────┐  ┌────┴─────┐                                    │
│  │ n8n-MCP  │  │ Postgres │                                    │
│  │ :3100    │  │ :5432    │                                    │
│  └──────────┘  └──────────┘                                    │
│                                                                 │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ Claude Code / OpenClaw (host-level orchestrators)     │       │
│  └──────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

| Service | Port | Purpose | Docker Hostname |
|---------|------|---------|-----------------|
| **Open WebUI** | 3000 | Chat UI + OpenAI-compatible API | `open-webui:8080` |
| **n8n** | 5678 | Workflow automation engine | `n8n:5678` |
| **n8n-MCP** | 3100 | MCP bridge (20 tools for Claude Code + Open WebUI) | `n8n-mcp:3100` |
| **Ollama** | 11434 | Local LLM inference (GPU-accelerated) | `ollama:11434` |
| **Qdrant** | 6333 | Vector database for RAG | `qdrant:6333` |
| **PostgreSQL** | 5432 | n8n backend + chat memory | `postgres:5432` |

**Key credential locations**: All in `/home/claw/Claude/self-hosted-ai-starter-kit/.env`

---

## 2. Quick Start

### Start the Stack

```bash
cd /home/claw/Claude/self-hosted-ai-starter-kit
sg docker -c "docker compose --profile gpu-nvidia up -d"
```

### Health Check (All Services)

```bash
# All containers
sg docker -c "docker compose --profile gpu-nvidia ps"

# Individual services
curl -sf http://localhost:5678/healthz && echo "n8n: OK"
curl -sf http://localhost:3100/health | jq .status     # n8n-MCP
curl -sf http://localhost:11434/api/tags | jq '.models[].name'  # Ollama
curl -sf http://localhost:6333/collections | jq '.result.collections[].name'  # Qdrant
curl -sf http://localhost:3000/health && echo "Open WebUI: OK"
```

### Stop / Restart

```bash
sg docker -c "docker compose --profile gpu-nvidia down"        # Stop all
sg docker -c "docker compose --profile gpu-nvidia restart n8n"  # Restart one service
```

### View Logs

```bash
sg docker -c "docker compose --profile gpu-nvidia logs -f open-webui"
sg docker -c "docker compose --profile gpu-nvidia logs -f n8n --tail=50"
```

---

## 3. Service Reference

### 3.1 Open WebUI

**URL**: http://localhost:3000
**Admin**: mike5150@protonmail.ch / localadmin2026
**API Key**: `sk-Pg8kZ6KQiJ3A8391LmXbPiYYPZ4PkIQrgFzs8jhcrglcFSVfWkwIuTl6hIXOTcLo`
**Version**: 0.7.2

**What it does**: Full-featured chat interface with OpenAI-compatible API. Connects to Ollama for local model inference. Supports RAG (knowledge bases), custom tools/functions, MCP servers, prompt templates, file uploads, and webhooks.

**Key features**:
- OpenAI-compatible `/api/chat/completions` endpoint
- Native MCP support (Streamable HTTP) -- n8n-MCP connected with 20 tools
- Knowledge base with vector search (RAG)
- Custom functions/tools (Python)
- File upload and processing
- Chat history with export
- Prompt templates with variables
- Webhook notifications (28+ event types)

### 3.2 n8n

**URL**: http://localhost:5678
**Purpose**: Visual workflow automation -- connects services, processes data, triggers actions.

**Current workflows**:
- `seed-webhooks` (active) -- Clone source for new trigger-based workflows
- `Tool Execution Webhook` (active) -- Generic webhook for Claude Code actions
- `Local RAG AI Agent` (inactive) -- Template RAG workflow
- `YouTube shorts/Gemini` (inactive) -- Content generation template

### 3.3 n8n-MCP Bridge

**URL**: http://localhost:3100
**Auth**: Bearer token (in `.env` as `N8N_MCP_AUTH_TOKEN`)
**Purpose**: Exposes 20 MCP tools to Claude Code and Open WebUI for programmatic n8n management.
**Integration**: Registered in both Claude Code (via `claude mcp add`) and Open WebUI (via `/api/v1/configs/tool_servers`).

**Tool categories**:
- **Discovery**: `search_nodes`, `get_node`, `search_templates`, `get_template`
- **Validation**: `validate_node`, `validate_workflow`
- **CRUD**: `n8n_list_workflows`, `n8n_get_workflow`, `n8n_create_workflow`, `n8n_update_*`, `n8n_delete_workflow`
- **Execution**: `n8n_test_workflow`, `n8n_executions`
- **Advanced**: `n8n_autofix_workflow`, `n8n_deploy_template`, `n8n_workflow_versions`
- **Meta**: `n8n_health_check`, `tools_documentation`

### 3.4 Ollama

**URL**: http://localhost:11434
**GPU**: NVIDIA (8GB VRAM)
**Installed model**: llama3.2 (3.2B, Q4_K_M)

**API endpoints**:
- `POST /api/chat` -- Multi-turn chat
- `POST /api/generate` -- Single-prompt generation
- `POST /api/embed` -- Generate embeddings
- `GET /api/tags` -- List models
- `POST /api/pull` -- Download model
- `POST /api/show` -- Model info
- `GET /api/ps` -- Running models + VRAM usage

### 3.5 Qdrant

**URL**: http://localhost:6333
**Purpose**: Vector database for semantic search / RAG pipelines.

**API endpoints**:
- `GET /collections` -- List collections
- `PUT /collections/{name}` -- Create collection
- `PUT /collections/{name}/points` -- Insert vectors
- `POST /collections/{name}/points/search` -- Semantic search
- `POST /collections/{name}/points/scroll` -- Paginated listing

### 3.6 PostgreSQL

**Internal only** (no external port).
**User**: `n8n_user` / **DB**: `n8n`
**Purpose**: n8n workflow storage, execution history, credentials.

---

## 4. Open WebUI API

The Open WebUI API is the most versatile integration point. It provides an OpenAI-compatible interface to local models, plus unique features like knowledge bases, memories, and webhooks.

### 4.1 Authentication

All API calls use the Bearer token:

```bash
# Stored in .env as OWUI_API_KEY
export OWUI_KEY="sk-Pg8kZ6KQiJ3A8391LmXbPiYYPZ4PkIQrgFzs8jhcrglcFSVfWkwIuTl6hIXOTcLo"

# Verify authentication
curl -s http://localhost:3000/api/models \
  -H "Authorization: Bearer $OWUI_KEY" | jq '.data[].id'
```

### 4.2 Chat Completions (OpenAI-Compatible)

This is the primary endpoint. Any tool that speaks the OpenAI API can target Open WebUI.

```bash
curl -s http://localhost:3000/api/chat/completions \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:latest",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Summarize the key benefits of RAG."}
    ],
    "stream": false,
    "temperature": 0.7
  }' | jq '.choices[0].message.content'
```

**Streaming**:
```bash
curl -N http://localhost:3000/api/chat/completions \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:latest",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": true
  }'
# Returns SSE: data: {"choices":[{"delta":{"content":"..."}}]}
```

### 4.3 Knowledge Bases (RAG)

Build searchable document collections that augment LLM responses.

```bash
# Create knowledge base
curl -s -X POST http://localhost:3000/api/v1/knowledge/create \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "Project Docs", "description": "Technical documentation"}' | jq .

# Upload a file
FILE_ID=$(curl -s -X POST http://localhost:3000/api/v1/files/ \
  -H "Authorization: Bearer $OWUI_KEY" \
  -F "file=@/path/to/document.pdf" | jq -r '.id')

# Add file to knowledge base
curl -s -X POST http://localhost:3000/api/v1/knowledge/{kb_id}/file/add \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"file_id\": \"$FILE_ID\"}"

# Query with RAG (files parameter)
curl -s http://localhost:3000/api/chat/completions \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:latest",
    "messages": [{"role": "user", "content": "What does the doc say about X?"}],
    "files": [{"type": "knowledge", "id": "KB_ID"}]
  }'
```

### 4.4 Memories

Persistent user memories that automatically augment future conversations.

```bash
# Add a memory
curl -s -X POST http://localhost:3000/api/v1/memories/add \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content": "The user prefers concise responses and dislikes emojis."}'

# List memories
curl -s http://localhost:3000/api/v1/memories/ \
  -H "Authorization: Bearer $OWUI_KEY" | jq '.[].content'
```

### 4.5 Prompt Templates

Reusable templates accessible via `/command-name` in the chat UI.

```bash
# Create template
curl -s -X POST http://localhost:3000/api/v1/prompts/create \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "command": "code-review",
    "title": "Code Review",
    "content": "Review this {{LANGUAGE}} code for bugs and improvements:\n\n{{CODE}}"
  }'
```

### 4.6 File Management

```bash
# Upload file
curl -s -X POST http://localhost:3000/api/v1/files/ \
  -H "Authorization: Bearer $OWUI_KEY" \
  -F "file=@report.pdf" | jq '{id, filename, meta}'

# List files
curl -s http://localhost:3000/api/v1/files/ \
  -H "Authorization: Bearer $OWUI_KEY" | jq '.[].filename'

# Download file
curl -s http://localhost:3000/api/v1/files/{id}/content \
  -H "Authorization: Bearer $OWUI_KEY" -o output.pdf
```

### 4.7 Chat History

```bash
# List chats
curl -s "http://localhost:3000/api/v1/chats/?page=1" \
  -H "Authorization: Bearer $OWUI_KEY" | jq '.[].chat.title'

# Get specific chat
curl -s http://localhost:3000/api/v1/chats/{id} \
  -H "Authorization: Bearer $OWUI_KEY" | jq '.chat.messages[-1].content'

# Delete chat
curl -s -X DELETE http://localhost:3000/api/v1/chats/{id} \
  -H "Authorization: Bearer $OWUI_KEY"
```

### 4.8 Webhooks

Open WebUI can POST notifications to external URLs on 28+ event types.

```bash
# Create webhook
curl -s -X POST http://localhost:3000/api/v1/webhooks \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "http://n8n:5678/webhook/owui-events",
    "events": ["chat.created", "chat.response"]
  }'
```

**Available events**: `auth.user.signup`, `chat.created`, `chat.response`, `admin.user.deleted`, and more.

---

## 5. n8n Workflow Automation

### 5.1 Creating Workflows

**Important**: Webhook and trigger nodes created via API don't register properly in n8n. Always use the seed workflow pattern.

**Seed workflow**: `dn2XjIQXbaTrElQL4tVrQ` (`seed-webhooks`)
Contains pre-initialized: Webhook, SSE Trigger, Chat Trigger, Manual Trigger, Apify, xAI Grok nodes.

**Clone pattern** (via n8n-MCP tools):
1. `n8n_get_workflow` -- Fetch seed workflow definition
2. `n8n_create_workflow` -- Create new workflow using seed's trigger nodes
3. `n8n_update_partial_workflow` -- Add your logic nodes and connections
4. Activate via `POST http://localhost:5678/api/v1/workflows/{id}/activate`

**For non-trigger workflows** (called by other workflows):
1. `search_nodes` -- Find the n8n nodes you need
2. `get_node` -- Get full node documentation
3. `validate_workflow` -- Validate before creating
4. `n8n_create_workflow` -- Create the workflow
5. `n8n_test_workflow` -- Test execution

### 5.2 Tool Execution Webhook

**Endpoint**: `POST http://localhost:5678/webhook/tool-execute`

The generic webhook workflow routes actions to different services:

```bash
# Route to Ollama
curl -s -X POST http://localhost:5678/webhook/tool-execute \
  -H "Content-Type: application/json" \
  -d '{
    "action": "ollama_generate",
    "model": "llama3.2",
    "prompt": "Explain Docker in one sentence"
  }'

# Route to Qdrant search
curl -s -X POST http://localhost:5678/webhook/tool-execute \
  -H "Content-Type: application/json" \
  -d '{
    "action": "qdrant_search",
    "collection": "documents",
    "query": "authentication flow"
  }'
```

### 5.3 n8n API Direct Access

```bash
# List workflows
curl -s http://localhost:5678/api/v1/workflows \
  -H "X-N8N-API-KEY: $(grep N8N_API_KEY /home/claw/Claude/self-hosted-ai-starter-kit/.env | cut -d= -f2)" \
  | jq '.data[] | {id, name, active}'

# Execute workflow
curl -s -X POST "http://localhost:5678/api/v1/workflows/{id}/run" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"data": {"key": "value"}}'
```

---

## 6. Ollama LLM Engine

### 6.1 Model Management

```bash
# List installed models
curl -s http://localhost:11434/api/tags | jq '.models[] | {name, size, modified_at}'

# Pull a new model
curl -X POST http://localhost:11434/api/pull -d '{"name":"nomic-embed-text"}'
curl -X POST http://localhost:11434/api/pull -d '{"name":"mistral:7b"}'

# Delete a model
curl -X DELETE http://localhost:11434/api/delete -d '{"name":"MODEL_NAME"}'

# Check GPU memory usage
curl -s http://localhost:11434/api/ps | jq '.models[] | {name, size, size_vram}'
```

### 6.2 Recommended Models

| Model | Size | VRAM | Use Case |
|-------|------|------|----------|
| llama3.2 | 2GB | ~2GB | Fast general tasks (installed) |
| nomic-embed-text | 274MB | ~300MB | Embeddings for RAG |
| mistral:7b | 4.1GB | ~5GB | Higher quality general |
| codellama:7b | 3.8GB | ~5GB | Code generation |
| phi3:mini | 2.3GB | ~3GB | Fast, good quality |

**VRAM constraint**: 8GB total. Only one 7B model can be loaded at a time alongside llama3.2.

### 6.3 Chat and Generation

```bash
# Chat (multi-turn)
curl -X POST http://localhost:11434/api/chat -d '{
  "model": "llama3.2",
  "messages": [
    {"role": "system", "content": "You are a technical writer."},
    {"role": "user", "content": "Write a one-paragraph summary of Docker."}
  ],
  "stream": false
}' | jq '.message.content'

# Single-shot generation
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Translate to French: Hello, how are you?",
  "stream": false
}' | jq '.response'

# Embeddings
curl -X POST http://localhost:11434/api/embed -d '{
  "model": "nomic-embed-text",
  "input": "Text to embed for vector search"
}' | jq '.embeddings[0][:5]'
```

---

## 7. Qdrant Vector Database

### 7.1 Collection Management

```bash
# Create a collection (768 dims = nomic-embed-text)
curl -X PUT http://localhost:6333/collections/documents \
  -H "Content-Type: application/json" \
  -d '{"vectors": {"size": 768, "distance": "Cosine"}}'

# Collection info
curl -s http://localhost:6333/collections/documents | jq '.result | {points_count, segments_count}'

# Delete collection
curl -X DELETE http://localhost:6333/collections/documents
```

### 7.2 Insert and Search

```bash
# Insert point
curl -X PUT http://localhost:6333/collections/documents/points \
  -H "Content-Type: application/json" \
  -d '{
    "points": [{
      "id": 1,
      "vector": [0.1, 0.2, ...],
      "payload": {"text": "Document content", "source": "file.md", "date": "2026-02-05"}
    }]
  }'

# Semantic search
curl -X POST http://localhost:6333/collections/documents/points/search \
  -H "Content-Type: application/json" \
  -d '{
    "vector": [0.1, 0.2, ...],
    "limit": 5,
    "with_payload": true,
    "score_threshold": 0.7
  }'

# Filter search (by payload field)
curl -X POST http://localhost:6333/collections/documents/points/search \
  -H "Content-Type: application/json" \
  -d '{
    "vector": [0.1, 0.2, ...],
    "limit": 5,
    "with_payload": true,
    "filter": {
      "must": [{"key": "source", "match": {"value": "important.md"}}]
    }
  }'
```

---

## 8. Integration Patterns

These are the real power moves -- combining services into unified workflows.

### 8.1 Open WebUI as Universal LLM Gateway

**Pattern**: Use Open WebUI's API as the single entry point for all LLM calls, regardless of whether the caller is Claude Code, n8n, a script, or an external tool.

**Why**: Open WebUI handles model routing, maintains chat history, and applies RAG automatically when knowledge bases are attached.

```bash
# Any OpenAI-compatible client can use this
export OPENAI_API_KEY="sk-Pg8kZ6KQiJ3A8391LmXbPiYYPZ4PkIQrgFzs8jhcrglcFSVfWkwIuTl6hIXOTcLo"
export OPENAI_BASE_URL="http://localhost:3000/api"

# Python (openai SDK)
# pip install openai
python3 -c "
from openai import OpenAI
client = OpenAI(base_url='http://localhost:3000/api', api_key='$OPENAI_API_KEY')
r = client.chat.completions.create(model='llama3.2:latest', messages=[{'role':'user','content':'Hello'}])
print(r.choices[0].message.content)
"
```

**Use cases**:
- n8n workflows call Open WebUI instead of Ollama directly (gets RAG for free)
- Scripts use the OpenAI SDK pointed at localhost:3000
- External tools (Cursor, Continue.dev) can target the same endpoint

### 8.2 RAG Pipeline: Ollama + Qdrant + Open WebUI

**End-to-end document Q&A**:

```bash
# 1. Pull embedding model
curl -X POST http://localhost:11434/api/pull -d '{"name":"nomic-embed-text"}'

# 2. Create Qdrant collection
curl -X PUT http://localhost:6333/collections/project-docs \
  -H "Content-Type: application/json" \
  -d '{"vectors":{"size":768,"distance":"Cosine"}}'

# 3. Embed and store a document
EMBEDDING=$(curl -s http://localhost:11434/api/embed \
  -d '{"model":"nomic-embed-text","input":"Your document text here"}' \
  | jq '.embeddings[0]')

curl -X PUT http://localhost:6333/collections/project-docs/points \
  -H "Content-Type: application/json" \
  -d "{\"points\":[{\"id\":1,\"vector\":$EMBEDDING,\"payload\":{\"text\":\"Your document text here\",\"source\":\"readme.md\"}}]}"

# 4. Search and generate answer
QUERY_VEC=$(curl -s http://localhost:11434/api/embed \
  -d '{"model":"nomic-embed-text","input":"What does the project do?"}' \
  | jq '.embeddings[0]')

CONTEXT=$(curl -s http://localhost:6333/collections/project-docs/points/search \
  -d "{\"vector\":$QUERY_VEC,\"limit\":3,\"with_payload\":true}" \
  | jq -r '.result[].payload.text' | head -c 2000)

curl -s http://localhost:11434/api/chat -d "{
  \"model\":\"llama3.2\",
  \"messages\":[
    {\"role\":\"system\",\"content\":\"Answer based on this context: $CONTEXT\"},
    {\"role\":\"user\",\"content\":\"What does the project do?\"}
  ],\"stream\":false}" | jq '.message.content'
```

**Or, simpler via Open WebUI** (handles RAG automatically):
1. Upload files to a Knowledge Base via the API
2. Query with `"files": [{"type": "knowledge", "id": "KB_ID"}]` in completions

### 8.3 n8n + Open WebUI Bidirectional Integration

**n8n calls Open WebUI** (workflow uses LLM with RAG):

In an n8n HTTP Request node:
- **Method**: POST
- **URL**: `http://open-webui:8080/api/chat/completions`
- **Headers**: `Authorization: Bearer sk-Pg8kZ6KQ...`
- **Body**: `{"model":"llama3.2:latest","messages":[...],"stream":false}`

**Open WebUI calls n8n** (chat triggers workflow):

Configure a webhook in Open WebUI to POST to n8n:
- **Open WebUI webhook URL**: `http://n8n:5678/webhook/owui-events`
- **Events**: `chat.created`, `chat.response`

This enables:
- Every chat in Open WebUI can trigger an n8n workflow
- n8n can process the chat, enrich it, log it, or trigger follow-up actions

### 8.4 Claude Code + Open WebUI: Complementary AI

**Pattern**: Claude Code uses Open WebUI API to delegate tasks to local models when cloud AI is overkill or when you want to keep data local.

```bash
# From Claude Code, send a task to local Ollama via Open WebUI
curl -s http://localhost:3000/api/chat/completions \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:latest",
    "messages": [{"role": "user", "content": "Reformat this JSON: {\"a\":1,\"b\":2}"}],
    "stream": false
  }' | jq -r '.choices[0].message.content'
```

**Use cases**:
- Data formatting/transformation (keep data local)
- Bulk text processing (no API costs)
- Embedding generation for search
- Draft generation before Claude review

### 8.5 MCP Tool Chain: Claude Code -> n8n-MCP -> n8n -> Services

Both Claude Code and Open WebUI have direct access to 20 n8n-MCP tools:

```
Claude Code ──┐
              ├──> n8n-MCP (search_nodes, validate_workflow, n8n_create_workflow)
Open WebUI ───┘      └─> n8n API
                           └─> Webhook triggers, HTTP requests, data processing
                                 └─> Ollama, Qdrant, external APIs
```

Example: Claude Code can programmatically build an n8n workflow that processes data through Ollama and stores results in Qdrant -- all without touching the n8n UI.

### 8.6 Open WebUI MCP Server Config API

MCP servers in Open WebUI are managed via the `/api/v1/configs/tool_servers` endpoint:

```bash
# List configured MCP servers
curl -s http://localhost:3000/api/v1/configs/tool_servers \
  -H "Authorization: Bearer $OWUI_KEY"

# Add/replace MCP server config
curl -s -X POST http://localhost:3000/api/v1/configs/tool_servers \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "TOOL_SERVER_CONNECTIONS": [{
      "url": "http://n8n-mcp:3100/mcp",
      "path": "",
      "type": "mcp",
      "auth_type": "bearer",
      "key": "YOUR_MCP_AUTH_TOKEN",
      "config": {}
    }]
  }'

# Verify connection before saving
curl -s -X POST http://localhost:3000/api/v1/configs/tool_servers/verify \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "http://n8n-mcp:3100/mcp",
    "path": "",
    "type": "mcp",
    "auth_type": "bearer",
    "key": "YOUR_MCP_AUTH_TOKEN",
    "config": {}
  }'
```

**ToolServerConnection schema**: `url` (string), `path` (string), `type` ("mcp" or "openapi"), `auth_type` ("bearer", "session", "oauth_2.1", "none"), `key` (optional string), `headers` (optional dict), `config` (optional dict).

---

## 9. Automation Recipes

### Recipe 1: Document Ingestion Pipeline

**Goal**: Drop a file, have it automatically embedded and searchable.

**Implementation**: n8n workflow with Webhook trigger:
1. POST document to webhook
2. Extract text (n8n Code node)
3. Chunk text into passages
4. Embed each chunk via Ollama `/api/embed`
5. Store embeddings in Qdrant collection
6. Return confirmation with chunk count

### Recipe 2: Daily Knowledge Digest

**Goal**: Automatically summarize new content added to knowledge bases.

**Implementation**: n8n scheduled workflow:
1. Cron trigger (daily at 8 AM)
2. Query Qdrant for points added in last 24h (filter by date payload)
3. Concatenate text payloads
4. Send to Open WebUI API for summarization
5. Save summary to Open WebUI memories (so it augments future chats)
6. Optional: POST to Telegram via OpenClaw gateway

### Recipe 3: Multi-Model Consensus

**Goal**: Get answers from multiple models and compare.

**Implementation** (script or n8n workflow):
```bash
QUESTION="What are the security implications of running Docker in WSL2?"

# Ask llama3.2 via Open WebUI
ANSWER1=$(curl -s http://localhost:3000/api/chat/completions \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"llama3.2:latest\",\"messages\":[{\"role\":\"user\",\"content\":\"$QUESTION\"}],\"stream\":false}" \
  | jq -r '.choices[0].message.content')

# If you had mistral:7b installed, ask it too
# ANSWER2=$(same call with "model":"mistral:7b")

echo "llama3.2 says: $ANSWER1"
```

### Recipe 4: Automated Code Documentation

**Goal**: Generate documentation for code files using local LLM.

```bash
# Process each Python file in a directory
for f in /path/to/project/*.py; do
  CONTENT=$(cat "$f" | head -200)
  DOC=$(curl -s http://localhost:3000/api/chat/completions \
    -H "Authorization: Bearer $OWUI_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"llama3.2:latest\",\"messages\":[
      {\"role\":\"system\",\"content\":\"Generate a brief docstring for this Python module.\"},
      {\"role\":\"user\",\"content\":$(echo "$CONTENT" | jq -Rs .)}
    ],\"stream\":false}" \
    | jq -r '.choices[0].message.content')
  echo "=== $f ===" >> docs.md
  echo "$DOC" >> docs.md
  echo "" >> docs.md
done
```

### Recipe 5: Smart Notification Router

**Goal**: Use LLM to classify and route notifications.

**n8n workflow**:
1. Webhook receives notification JSON `{source, message, priority}`
2. Send to Open WebUI: "Classify this notification: [message]. Categories: urgent, info, spam"
3. Switch node routes based on classification
4. Urgent -> Telegram via OpenClaw gateway
5. Info -> Store in Qdrant for later search
6. Spam -> Discard with log entry

### Recipe 6: Conversational Search Over Local Data

**Goal**: Ask natural language questions about your stored documents.

```bash
# Assume Qdrant has a "docs" collection with embedded documents

QUESTION="How does the authentication system work?"

# 1. Embed the question
Q_VEC=$(curl -s http://localhost:11434/api/embed \
  -d "{\"model\":\"nomic-embed-text\",\"input\":\"$QUESTION\"}" | jq '.embeddings[0]')

# 2. Search Qdrant
RESULTS=$(curl -s http://localhost:6333/collections/docs/points/search \
  -d "{\"vector\":$Q_VEC,\"limit\":5,\"with_payload\":true}" \
  | jq -r '[.result[].payload.text] | join("\n---\n")')

# 3. Generate answer with context
curl -s http://localhost:3000/api/chat/completions \
  -H "Authorization: Bearer $OWUI_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"llama3.2:latest\",\"messages\":[
    {\"role\":\"system\",\"content\":\"Answer the question using ONLY the provided context. If the context doesn't contain the answer, say so.\"},
    {\"role\":\"user\",\"content\":\"Context:\\n$RESULTS\\n\\nQuestion: $QUESTION\"}
  ],\"stream\":false}" | jq -r '.choices[0].message.content'
```

### Recipe 7: Open WebUI as OpenClaw Sub-Agent Backend

**Goal**: OpenClaw's Forge agent uses Open WebUI for local inference tasks.

OpenClaw can call the Open WebUI API as a tool, enabling Forge to:
- Run local inference without using cloud API credits
- Query knowledge bases that have been built up in Open WebUI
- Use different models for different tasks (llama3.2 for fast, mistral for quality)
- Store conversation memories that persist across sessions

### Recipe 8: Webhook-Driven Chat Logging

**Goal**: Log all Open WebUI conversations to a searchable archive.

1. Configure Open WebUI webhook: `http://n8n:5678/webhook/chat-logger`
2. n8n workflow:
   - Receive webhook payload
   - Extract chat messages, model used, timestamp
   - Embed the conversation text
   - Store in Qdrant "chat-archive" collection
3. Later: search chat history semantically via Qdrant

---

## 10. Security & Operations

### 10.1 Credentials Summary

| Credential | Location | Purpose |
|------------|----------|---------|
| `POSTGRES_USER/PASSWORD` | `.env` | Database access |
| `N8N_ENCRYPTION_KEY` | `.env` | n8n secrets encryption |
| `N8N_MCP_AUTH_TOKEN` | `.env` | MCP bridge authentication |
| `N8N_API_KEY` | `.env` | n8n REST API (JWT) |
| `WEBUI_SECRET_KEY` | `.env` | Open WebUI JWT signing |
| `OWUI_API_KEY` | `.env` | Open WebUI API access |
| Open WebUI admin password | `localadmin2026` | Web UI login |

### 10.2 Network Security

- All services bind to `localhost` only -- not accessible from outside WSL2
- Docker network `demo` provides inter-container communication
- No TLS (not needed for localhost-only deployment)
- n8n-MCP requires Bearer token authentication
- Open WebUI API requires API key or JWT

### 10.3 Backup

```bash
# Backup all Docker volumes
sg docker -c "docker compose --profile gpu-nvidia down"
for vol in n8n_storage postgres_storage ollama_storage qdrant_storage n8n_mcp_data open_webui_data; do
  sg docker -c "docker run --rm -v self-hosted-ai-starter-kit_${vol}:/data -v /tmp/backups:/backup alpine tar czf /backup/${vol}.tar.gz -C /data ."
done
sg docker -c "docker compose --profile gpu-nvidia up -d"

# Backup .env and compose
cp .env /tmp/backups/
cp docker-compose.yml /tmp/backups/
```

### 10.4 Resource Monitoring

```bash
# Container resource usage
sg docker -c "docker stats --no-stream"

# GPU memory
curl -s http://localhost:11434/api/ps | jq '.models[] | {name, size_vram}'

# Disk usage by volume
sg docker -c "docker system df -v" | head -30
```

### 10.5 Updating Services

```bash
# Pull latest images
sg docker -c "docker compose --profile gpu-nvidia pull"

# Recreate with new images (data persists in volumes)
sg docker -c "docker compose --profile gpu-nvidia up -d"
```

---

## 11. Troubleshooting

### n8n-MCP "Session not found or expired"

**Cause**: Claude Code caches MCP session IDs in-memory. Container restarts invalidate them.
**Fix**: Start a new Claude Code session. Session timeout is 24 hours (`SESSION_TIMEOUT_MINUTES=1440`).

### n8n Webhook Returns 404

**Cause**: Webhooks created via API don't register in n8n's webhook listener.
**Fix**: Use the seed workflow clone pattern (see Section 5.1). Create trigger nodes manually in the UI, then clone via API.

### Ollama Model Won't Load (OOM)

**Cause**: 8GB VRAM exceeded.
**Fix**: Unload current model: `curl -X POST http://localhost:11434/api/generate -d '{"model":"MODEL","keep_alive":0}'`. Then load the smaller model.

### Open WebUI Chat Returns Empty Response

**Cause**: Ollama model not loaded or connection timeout.
**Fix**: Check `curl -s http://localhost:11434/api/ps` to verify model is loaded. If empty, send any request to load it.

### Open WebUI API Returns 401

**Cause**: API key not found or expired.
**Fix**: Verify key exists in database: `sg docker -c "docker exec open-webui python3 -c \"import sqlite3; conn=sqlite3.connect('/app/backend/data/webui.db'); print(conn.execute('SELECT key FROM api_key').fetchall()); conn.close()\""`

### Docker Compose Won't Start

**Cause**: Usually port conflicts or missing `.env` values.
**Fix**: `sg docker -c "docker compose --profile gpu-nvidia config"` to validate. Check `ss -tlnp | grep -E '3000|5678|3100|6333|11434'` for port conflicts.

### PostgreSQL Health Check Failing

**Cause**: Database initialization still in progress or credentials mismatch.
**Fix**: Check `sg docker -c "docker compose --profile gpu-nvidia logs postgres"`. Verify `POSTGRES_USER` and `POSTGRES_PASSWORD` in `.env`.

---

## Appendix A: Complete API Quick Reference

### Open WebUI Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/chat/completions` | Chat completion (OpenAI-compat) |
| GET | `/api/models` | List available models |
| POST | `/api/v1/knowledge/create` | Create knowledge base |
| POST | `/api/v1/knowledge/{id}/file/add` | Add file to KB |
| POST | `/api/v1/files/` | Upload file |
| GET | `/api/v1/files/` | List files |
| POST | `/api/v1/memories/add` | Add memory |
| GET | `/api/v1/memories/` | List memories |
| POST | `/api/v1/prompts/create` | Create prompt template |
| GET | `/api/v1/chats/` | List chats |
| POST | `/api/v1/webhooks` | Create webhook |

### Ollama Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/chat` | Multi-turn chat |
| POST | `/api/generate` | Single generation |
| POST | `/api/embed` | Generate embeddings |
| GET | `/api/tags` | List models |
| POST | `/api/pull` | Download model |
| POST | `/api/show` | Model info |
| GET | `/api/ps` | Running models |

### Qdrant Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/collections` | List collections |
| PUT | `/collections/{name}` | Create collection |
| PUT | `/collections/{name}/points` | Insert points |
| POST | `/collections/{name}/points/search` | Search |
| POST | `/collections/{name}/points/scroll` | List/paginate |

### n8n-MCP Tools (via Claude Code)

| Tool | Purpose |
|------|---------|
| `search_nodes` | Search 800+ n8n nodes |
| `get_node` | Get node documentation |
| `search_templates` | Search workflow templates |
| `validate_workflow` | Validate workflow JSON |
| `n8n_create_workflow` | Create workflow |
| `n8n_list_workflows` | List all workflows |
| `n8n_test_workflow` | Execute workflow |
| `n8n_health_check` | Check n8n connectivity |

---

## Appendix B: Environment Variables

```bash
# PostgreSQL
POSTGRES_USER=n8n_user
POSTGRES_PASSWORD=<generated>
POSTGRES_DB=n8n

# n8n
N8N_ENCRYPTION_KEY=<generated>
N8N_USER_MANAGEMENT_JWT_SECRET=<generated>

# n8n-MCP Bridge
N8N_MCP_AUTH_TOKEN=<generated>
N8N_API_KEY=<JWT token>

# Open WebUI
WEBUI_SECRET_KEY=<generated>
OWUI_API_KEY=<generated>  # For reference; stored in DB
```

---

## Appendix C: Decision Tree

```
What do you need?
│
├── Chat with a local LLM?
│   ├── Interactive (browser) → Open WebUI (localhost:3000)
│   ├── Programmatic (API) → Open WebUI API (/api/chat/completions)
│   └── Direct (no middleware) → Ollama API (localhost:11434/api/chat)
│
├── Automate a workflow?
│   ├── Visual builder → n8n UI (localhost:5678)
│   ├── Programmatic → n8n-MCP tools (via Claude Code)
│   └── Simple webhook → POST to localhost:5678/webhook/tool-execute
│
├── Store/search documents?
│   ├── With chat UI → Open WebUI Knowledge Bases
│   ├── Programmatic → Qdrant API (localhost:6333) + Ollama embeddings
│   └── Via n8n workflow → Automated ingestion pipeline
│
├── Manage models?
│   ├── Pull/delete → Ollama API (localhost:11434/api/pull)
│   └── Check GPU usage → Ollama API (localhost:11434/api/ps)
│
├── Build a RAG pipeline?
│   ├── Quick (manual) → Open WebUI Knowledge Base
│   └── Custom (automated) → Ollama embed + Qdrant store + Ollama chat
│
└── Manage infrastructure?
    ├── Start/stop → sg docker -c "docker compose --profile gpu-nvidia ..."
    ├── Logs → docker compose logs -f <service>
    └── Resources → docker stats --no-stream
```
