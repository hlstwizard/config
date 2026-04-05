#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib.sh"

ensure_runtime_dirs

print_status() {
	local name="$1"
	local port="$2"
	local pid_file="${RUN_DIR}/${name}.pid"

	if [[ ! -f "${pid_file}" ]]; then
		echo "${name}: stopped"
		return 0
	fi

	local pid
	pid="$(cat "${pid_file}")"
	if kill -0 "${pid}" >/dev/null 2>&1; then
		echo "${name}: running (pid ${pid}) http://127.0.0.1:${port}/mcp"
	else
		echo "${name}: stale pid file (${pid})"
	fi
}

while IFS='|' read -r name enabled port raw_command; do
	if [[ "${enabled}" != "1" ]]; then
		echo "${name}: disabled"
		continue
	fi
	print_status "${name}" "${port}"
done < <(read_servers)
