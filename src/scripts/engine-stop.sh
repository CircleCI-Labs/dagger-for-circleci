#!/bin/bash

# Dagger Engine cleanup script
# Stops Dagger Engine containers using Docker directly

set -euo pipefail

if command -v docker >/dev/null 2>&1; then
    mapfile -t containers < <(docker ps --filter name="dagger-engine-*" -q)
    if [[ "${#containers[@]}" -gt 0 ]]; then
        echo "Stopping Dagger Engine containers..."
        docker stop -t 300 "${containers[@]}"
        echo "Dagger Engine stopped successfully"
    else
        echo "No Dagger Engine containers found"
    fi
else
    echo "Docker not available, skipping engine stop"
fi 