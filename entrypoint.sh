#!/usr/bin/env bash
# =============================================================
# picoclaw-toolbox entrypoint
# Handles config scaffolding and mode dispatch
# =============================================================
set -euo pipefail

CONFIG_FILE="${PICOCLAW_CONFIG:-/root/.picoclaw/config.json}"
CONFIG_DIR="$(dirname "$CONFIG_FILE")"

# ── Ensure config exists ──────────────────────────────────────
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[entrypoint] No config.json found at $CONFIG_FILE"

    # If a config volume is mounted and has one, use it
    if [ -f "/root/.picoclaw/config/config.json" ]; then
        echo "[entrypoint] Using config from mounted volume"
        cp /root/.picoclaw/config/config.json "$CONFIG_FILE"
    else
        echo "[entrypoint] Copying example config — edit $CONFIG_FILE before use"
        mkdir -p "$CONFIG_DIR"
        cp /root/.picoclaw/config.example.json "$CONFIG_FILE"
    fi
fi

# ── Mode dispatch ─────────────────────────────────────────────
MODE="${1:-gateway}"

case "$MODE" in
    gateway)
        echo "[entrypoint] Starting picoclaw in gateway mode..."
        exec picoclaw gateway
        ;;
    agent)
        shift
        echo "[entrypoint] Running picoclaw agent: $*"
        exec picoclaw agent "$@"
        ;;
    shell|bash)
        echo "[entrypoint] Starting interactive shell..."
        exec /bin/bash
        ;;
    version|--version|-v)
        exec picoclaw --version
        ;;
    *)
        # Pass-through: allow arbitrary picoclaw subcommands or other binaries
        exec "$@"
        ;;
esac
