#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# DeepseekCodexProxy — launch wrapper for @codeproxy/cli

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${THIS_DIR}/env"

# ── Parse key=value env file safely (no sourcing to avoid injection) ──
if [[ ! -r "$ENV_FILE" ]]; then
  echo "ERROR: missing or unreadable env file: $ENV_FILE" 1>&2
  echo "Create it from env.example and set DEEPSEEK_API_KEY." 1>&2
  exit 1
fi

DEEPSEEK_API_KEY="$(grep -E '^DEEPSEEK_API_KEY=' "$ENV_FILE" | head -1 | sed 's/^DEEPSEEK_API_KEY=//')"
LOG_DIR="$(grep -E '^LOG_DIR=' "$ENV_FILE" | head -1 | sed 's/^LOG_DIR=//' || true)"
LOG_DIR="${LOG_DIR:-/var/log/deepseek-proxy}"

if [[ -z "$DEEPSEEK_API_KEY" ]]; then
  echo "ERROR: DEEPSEEK_API_KEY is empty or not set in $ENV_FILE" 1>&2
  exit 1
fi

export DEEPSEEK_API_KEY

# ── Logging ────────────────────────────────────────────────────────────
mkdir -p "$LOG_DIR"
find "$LOG_DIR" -type f -mmin +60 -delete 2>/dev/null || true
export CODEPROXY_LOG_DIR="$LOG_DIR"

# ── Launch the proxy ───────────────────────────────────────────────────
exec "${THIS_DIR}/node_modules/.bin/codeproxy" \
  --config "${THIS_DIR}/config.json" \
  --apikey "${DEEPSEEK_API_KEY}"
