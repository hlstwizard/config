#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib.sh"

ensure_runtime_dirs
load_env_file

if [[ -z "${CONTEXT7_API_KEY-}" ]]; then
	echo "warn: CONTEXT7_API_KEY is empty. start may fail for servers requiring it." >&2
fi

start_server() {
	local name="$1"
	local port="$2"
	local stdio_command="$3"
	local pid_file="${RUN_DIR}/${name}.pid"
	local log_file="${LOG_DIR}/${name}.log"

	if [[ -f "${pid_file}" ]]; then
		local existing_pid
		existing_pid="$(cat "${pid_file}")"
		if kill -0 "${existing_pid}" >/dev/null 2>&1; then
			echo "ok: ${name} already running (pid ${existing_pid}, port ${port})"
			return 0
		fi
		rm -f "${pid_file}"
	fi

	nohup npx -y supergateway \
		--stdio "${stdio_command}" \
		--outputTransport streamableHttp \
		--port "${port}" \
		--streamableHttpPath /mcp \
		--healthEndpoint /healthz \
		--logLevel info \
		>"${log_file}" 2>&1 &

	local pid=$!
	sleep 1
	if ! kill -0 "${pid}" >/dev/null 2>&1; then
		echo "error: failed to start ${name}. see ${log_file}" >&2
		exit 3
	fi

	echo "${pid}" >"${pid_file}"
	echo "started: ${name} pid=${pid} url=http://127.0.0.1:${port}/mcp"
}

while IFS='|' read -r name enabled port raw_command; do
	if [[ "${enabled}" != "1" ]]; then
		echo "skip: ${name} disabled"
		continue
	fi

	resolved_command="$(expand_command "${raw_command}")"
	start_server "${name}" "${port}" "${resolved_command}"
done < <(read_servers)

echo "all MCP daemons are up"
