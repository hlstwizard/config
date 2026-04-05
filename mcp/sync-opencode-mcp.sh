#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib.sh"

OPENCODE_CONFIG_FILE_DEFAULT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)/opencode/opencode.json"
OPENCODE_CONFIG_FILE="${OPENCODE_CONFIG_FILE:-${OPENCODE_CONFIG_FILE_DEFAULT}}"

require_servers_file

if [[ ! -f "${OPENCODE_CONFIG_FILE}" ]]; then
	echo "error: OpenCode config not found: ${OPENCODE_CONFIG_FILE}" >&2
	exit 2
fi

python3 - "${SERVERS_FILE}" "${OPENCODE_CONFIG_FILE}" <<'PY'
import json
import sys

servers_file = sys.argv[1]
opencode_file = sys.argv[2]

mcp = {}
with open(servers_file, "r", encoding="utf-8") as f:
    for lineno, raw in enumerate(f, start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue

        parts = line.split("|", 3)
        if len(parts) != 4:
            print(f"warn: invalid line {lineno} in {servers_file}: {line}", file=sys.stderr)
            continue

        name, enabled, port, _command = parts
        if enabled != "1":
            continue

        mcp[name] = {
            "type": "remote",
            "url": f"http://127.0.0.1:{port}/mcp",
        }

with open(opencode_file, "r", encoding="utf-8") as f:
    cfg = json.load(f)

cfg["mcp"] = mcp

with open(opencode_file, "w", encoding="utf-8") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
PY

echo "synced: ${OPENCODE_CONFIG_FILE} mcp <- ${SERVERS_FILE}"
