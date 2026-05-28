#!/bin/bash
set -Eeuo pipefail

# This script is run whenever the container is started ensuring the latest catnip code
# is installed and running.

CONTAINER_DIR="/workspaces/catnip/container"
CATNIP_BIN="/home/vscode/.local/bin/catnip"
STAMP_FILE="/home/vscode/.cache/catnip/container-source.sha256"

mkdir -p "$(dirname "$STAMP_FILE")"

# Hash container source files to detect code changes between starts.
current_hash="$({
	find "$CONTAINER_DIR" -type f \
		! -path "$CONTAINER_DIR/.git/*" \
		! -path "$CONTAINER_DIR/bin/*" \
		! -path "$CONTAINER_DIR/build/*" \
		-print0 | sort -z | xargs -0 sha256sum
} | sha256sum | awk '{print $1}')"

previous_hash=""
if [[ -f "$STAMP_FILE" ]]; then
	previous_hash="$(cat "$STAMP_FILE")"
fi

needs_install=false
if [[ ! -x "$CATNIP_BIN" ]]; then
	needs_install=true
elif [[ "$current_hash" != "$previous_hash" ]]; then
	needs_install=true
fi

if [[ "$needs_install" == true ]]; then
	echo "Container sources changed, rebuilding catnip binary"
	sudo service catnip stop || true
	rm -f "$CATNIP_BIN"
	(cd "$CONTAINER_DIR" && just install)
	printf '%s\n' "$current_hash" > "$STAMP_FILE"

	echo "Restarting catnip service"
	sudo service catnip start
else
	echo "No container changes detected, skipping catnip rebuild"
	sudo service catnip status >/dev/null 2>&1 || sudo service catnip start
fi
