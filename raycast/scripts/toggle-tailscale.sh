#!/bin/zsh

# @raycast.schemaVersion 1
# @raycast.title Toggle Tailscale
# @raycast.mode compact
# @raycast.packageName Network
# @raycast.icon 🔐
# @raycast.description Toggle Tailscale connection on or off

set -euo pipefail

TAILSCALE_CLI="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

if [[ ! -x "$TAILSCALE_CLI" ]]; then
  echo "Tailscale app CLI not found at $TAILSCALE_CLI"
  exit 1
fi

get_state() {
  "$TAILSCALE_CLI" status --json 2>/dev/null | jq -r '.BackendState // ""' 2>/dev/null || true
}

state="$(get_state)"

if [ "$state" = "Running" ]; then
  if "$TAILSCALE_CLI" down >/dev/null 2>&1; then
    echo "Tailscale disconnected"
  else
    echo "Failed to disconnect Tailscale"
    exit 1
  fi
else
  if "$TAILSCALE_CLI" up >/dev/null 2>&1; then
    echo "Tailscale connected"
  else
    echo "Failed to connect Tailscale"
    exit 1
  fi
fi
