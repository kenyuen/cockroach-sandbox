#!/bin/bash
# Session start hook for cockroach-sandbox
# Runs only in remote Claude Code on the web sessions.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Copy .env from sample if not present
if [ ! -f "$CLAUDE_PROJECT_DIR/.env" ]; then
  cp "$CLAUDE_PROJECT_DIR/.env.sample" "$CLAUDE_PROJECT_DIR/.env"
  echo "[session-start] Created .env from .env.sample"
fi

# Copy liquibase/.env from sample if not present
if [ ! -f "$CLAUDE_PROJECT_DIR/liquibase/.env" ]; then
  cp "$CLAUDE_PROJECT_DIR/liquibase/.env.sample" "$CLAUDE_PROJECT_DIR/liquibase/.env"
  echo "[session-start] Created liquibase/.env from liquibase/.env.sample"
fi

# Verify Python 3 is available (required for seed/seed_customers.py)
if ! command -v python3 &>/dev/null; then
  echo "[session-start] WARNING: python3 not found — seed/seed_customers.py will not work"
else
  echo "[session-start] python3 available: $(python3 --version)"
fi

# Verify docker compose is available
if command -v docker &>/dev/null && docker compose version &>/dev/null 2>&1; then
  echo "[session-start] docker compose available: $(docker compose version)"
elif command -v docker-compose &>/dev/null; then
  echo "[session-start] docker-compose available: $(docker-compose --version)"
else
  echo "[session-start] WARNING: docker compose not found — cluster commands will not work"
fi

echo "[session-start] cockroach-sandbox environment ready"
