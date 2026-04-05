#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib.sh"

ensure_runtime_dirs

stop_server() {
	local name="$1"
	local pid_file="${RUN_DIR}/${name}.pid"

	if [[ ! -f "${pid_file}" ]]; then
		echo "skip: ${name} not running (no pid file)"
		return 0
	fi

	local pid
	pid="$(cat "${pid_file}")"
	if ! kill -0 "${pid}" >/dev/null 2>&1; then
		echo "skip: ${name} pid ${pid} already stopped"
		rm -f "${pid_file}"
		return 0
	fi

	kill "${pid}" >/dev/null 2>&1 || true
	sleep 1
	if kill -0 "${pid}" >/dev/null 2>&1; then
		kill -9 "${pid}" >/dev/null 2>&1 || true
	fi

	rm -f "${pid_file}"
	echo "stopped: ${name} pid=${pid}"
}

while IFS='|' read -r name enabled port raw_command; do
	if [[ "${enabled}" != "1" ]]; then
		echo "skip: ${name} disabled"
		continue
	fi
	stop_server "${name}"
done < <(read_servers)
