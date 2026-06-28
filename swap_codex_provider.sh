#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.codex/config.toml"
SERVICE="deepseek-proxy.service"

usage() {
  echo "Usage: $(basename "$0") [gpt|deepseek]"
  echo ""
  echo "  (no arg)  Toggle between DeepSeek ↔ ChatGPT"
  echo "  gpt       Force ChatGPT (gpt-5.5)"
  echo "  deepseek  Force DeepSeek (deepseek-v4-pro)"
  exit 0
}

if [[ ! -f "$CONFIG" ]]; then
  echo "❌ Config not found: $CONFIG"
  exit 1
fi

systemctl_service() {
  if [[ "$(id -u)" -eq 0 ]]; then
    systemctl "$@"
  else
    sudo systemctl "$@"
  fi
}

case "${1:-}" in
  --help|-h) usage ;;
  gpt)       TARGET="gpt" ;;
  deepseek)  TARGET="deepseek" ;;
  "")        TARGET="" ;;  # toggle
  *)         echo "❌ Unknown argument: $1"; usage ;;
esac

# Detect current provider
CURRENT_IS_DEEPSEEK=false
grep -q '^model_provider = ' "$CONFIG" && CURRENT_IS_DEEPSEEK=true

# Determine action: if no arg, toggle; otherwise use explicit target
if [[ -z "$TARGET" ]]; then
  if $CURRENT_IS_DEEPSEEK; then
    TARGET="gpt"
  else
    TARGET="deepseek"
  fi
fi

# Atomic config rewrite
TMP="$(mktemp "${CONFIG}.tmp.XXXXXXXXXX")"
trap 'rm -f "$TMP"' EXIT

if [[ "$TARGET" == "gpt" ]]; then
  sed -e 's/^model = "[^"]*"/model = "gpt-5.5"/' \
      -e '/^model_provider = /d' \
      "$CONFIG" > "$TMP"
  mv "$TMP" "$CONFIG"
  systemctl_service disable --now "$SERVICE"
  echo "✅ Switched to ChatGPT (gpt-5.5)"
else
  sed -e 's/^model = "[^"]*"/model = "deepseek-v4-pro"/' \
      -e '/^model_provider = /d' \
      -e '/^model = "deepseek-v4-pro"/a model_provider = "deepseek_proxy"' \
      "$CONFIG" > "$TMP"
  mv "$TMP" "$CONFIG"
  systemctl_service enable --now "$SERVICE"
  echo "✅ Switched to DeepSeek (deepseek-v4-pro)"
fi

echo "ℹ️  Restart any apps or terminals currently using Codex so they pick up the provider change."
