# 🦐 picoclaw-toolbox

> **PicoClaw** on **Ubuntu 24.04** — pre-loaded with everything a multi-modal AI agent needs.

[![Build & Push](https://github.com/addeeandra/ai-toolbox/actions/workflows/build-push.yml/badge.svg)](https://github.com/addeeandra/ai-toolbox/actions/workflows/build-push.yml)
[![GHCR](https://img.shields.io/badge/ghcr.io-addeeandra%2Fai--toolbox-blue)](https://ghcr.io/addeeandra/ai-toolbox)

---

## What's inside

| Category           | Tools                                                                                                  |
| ------------------ | ------------------------------------------------------------------------------------------------------ |
| **PicoClaw**       | Latest binary for amd64 / arm64                                                                        |
| **Python AI**      | `anthropic`, `openai`, `langchain`, `google-generativeai`, `pydantic`                                  |
| **Vision**         | `Pillow`, `opencv-python-headless`, `imagemagick`, `tesseract-ocr`                                     |
| **Documents**      | `pypdf`, `python-docx`, `openpyxl`, `poppler-utils`                                                    |
| **Web**            | `playwright` (Chromium), `beautifulsoup4`, `httpx`                                                     |
| **Node.js**        | `@anthropic-ai/sdk`, `openai`, `@modelcontextprotocol/sdk` + MCP servers                               |
| **Media**          | `ffmpeg`, `sox`                                                                                        |
| **MCP**            | `mcp` Python SDK + `@modelcontextprotocol/server-filesystem`, `-github`, `-brave-search`               |
| **Dev tools**      | `gh` (GitHub CLI), `git`, `jq`, `ripgrep`                                                              |
| **Heavy (opt-in)** | `openai-whisper`, `chromadb`, `sentence-transformers` — pass `--build-arg INSTALL_HEAVY_PACKAGES=true` |

---

## Quick start

```bash
# 1. Copy and fill in your API keys
cp .env.example .env
# → edit .env with your ANTHROPIC_API_KEY, OPENAI_API_KEY, etc.

# 2. (Optional) customise the agent config
mkdir -p config
cp config.example.json config/config.json
# → edit config/config.json to change model, tools, channels, etc.
# → if skipped, the default example config is used automatically

# 3. Run gateway mode (persistent bot)
docker compose up -d picoclaw-gateway

# 4. One-shot agent query
docker compose run --rm picoclaw-agent -m "Summarise the latest AI news"

# 5. Interactive REPL
docker compose run --rm picoclaw-agent

# 6. Drop into a shell
docker compose run --rm picoclaw-shell
```

---

## GitHub Actions — GHCR publish

The workflow in `.github/workflows/build-push.yml`:

- Builds multi-arch images (`amd64`, `arm64`) via QEMU + Buildx
- Pushes to `ghcr.io/addeeandra/ai-toolbox` with version tags and `:latest`
- Runs a smoke test to verify the binary and key packages are present
- Caches layers via GitHub Actions cache for fast rebuilds
- Attaches SBOM and provenance attestations

No extra secrets are needed — it uses the built-in `GITHUB_TOKEN`.

---

## Environment variables

| Variable                | Default                              | Description            |
| ----------------------- | ------------------------------------ | ---------------------- |
| `ANTHROPIC_API_KEY`     | —                                    | Anthropic provider key |
| `OPENAI_API_KEY`        | —                                    | OpenAI provider key    |
| `OPENROUTER_API_KEY`    | —                                    | OpenRouter key         |
| `GROQ_API_KEY`          | —                                    | Groq key               |
| `BRAVE_SEARCH_API_KEY`  | —                                    | Brave Search API key   |
| `TELEGRAM_BOT_TOKEN`    | —                                    | Telegram channel token |
| `DISCORD_BOT_TOKEN`     | —                                    | Discord channel token  |
| `PICOCLAW_CONFIG`       | `/root/.picoclaw/config/config.json` | Config file path       |
| `PICOCLAW_DATA`         | `/root/.picoclaw`                    | Data root              |
| `PICOCLAW_GATEWAY_HOST` | `0.0.0.0`                            | Gateway bind address   |

---

## Volumes

| Mount                       | Contents                              |
| --------------------------- | ------------------------------------- |
| `/root/.picoclaw/workspace` | Sessions, memory, skills, cron jobs   |
| `/root/.picoclaw/config`    | `config.json` (read-only recommended) |

---

## Updating PicoClaw

Re-run the workflow with `workflow_dispatch`, or bump the `PICOCLAW_VERSION` input, to pin a specific release tag.

```bash
# Build locally with a specific picoclaw version
docker build --build-arg PICOCLAW_VERSION=v0.2.0 -t picoclaw-toolbox .
```
