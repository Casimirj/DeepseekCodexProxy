#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Install the DeepSeek Codex Proxy as a systemd system service.

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"

SYSTEMD_DIR="/etc/systemd/system"
UNIT_NAME="deepseek-proxy.service"
UNIT_SRC="${THIS_DIR}/${UNIT_NAME}"
UNIT_DST="${SYSTEMD_DIR}/${UNIT_NAME}"

# ── Pre-flight checks ──────────────────────────────────────────────────
command -v npm > /dev/null 2>&1 || {
  echo "ERROR: npm is not on PATH — install Node.js first." 1>&2
  exit 1
}

if [[ ! -f "${THIS_DIR}/env" ]]; then
  echo "ERROR: env not found.  Copy env.example and set your key:" 1>&2
  echo "  cp ${THIS_DIR}/env.example ${THIS_DIR}/env" 1>&2
  exit 1
fi

# ── Install npm dependencies (pins exact version) ──────────────────────
echo "→  Installing @codeproxy/cli…"
cd "$THIS_DIR"
npm install

if [[ ! -x "${THIS_DIR}/node_modules/.bin/codeproxy" ]]; then
  echo "ERROR: codeproxy binary not found after npm install." 1>&2
  exit 1
fi
echo "✓  Dependencies installed"

# ── Stop and remove old user-level service if present ──────────────────
systemctl --user stop  "$UNIT_NAME" 2>/dev/null || true
systemctl --user disable "$UNIT_NAME" 2>/dev/null || true
rm -f "${HOME}/.config/systemd/user/${UNIT_NAME}"

# ── Parse env safely for optional symlink ──────────────────────────────
SYMLINK_LOG_DIR="$(grep -E '^SYMLINK_LOG_DIR=' "${THIS_DIR}/env" | head -1 | sed 's/^SYMLINK_LOG_DIR=//' || true)"

if [[ -n "${SYMLINK_LOG_DIR:-}" ]]; then
  LOG_DIR="$(grep -E '^LOG_DIR=' "${THIS_DIR}/env" | head -1 | sed 's/^LOG_DIR=//' || true)"
  LOG_DIR="${LOG_DIR:-/var/log/deepseek-proxy}"
  mkdir -p "$(dirname "$SYMLINK_LOG_DIR")"
  rm -rf "$SYMLINK_LOG_DIR"
  ln -s "$LOG_DIR" "$SYMLINK_LOG_DIR"
  echo "✓  Symlinked ${SYMLINK_LOG_DIR} → ${LOG_DIR}"
fi

# ── Install the unit file ──────────────────────────────────────────────
sudo mkdir -p "$SYSTEMD_DIR"
sudo cp "$UNIT_SRC" "$UNIT_DST"
echo "✓  Copied ${UNIT_NAME} → ${SYSTEMD_DIR}"

# ── Enable & start ─────────────────────────────────────────────────────
sudo systemctl daemon-reload
sudo systemctl enable "$UNIT_NAME"
sudo systemctl start "$UNIT_NAME"

echo "✓  deepseek-proxy is installed, enabled, and running."
SYSTEMD_COLORS=1 systemctl --no-pager status deepseek-proxy | grep --color=never -E "Loaded|Active" | sed "s|^[[:space:]]*||"

