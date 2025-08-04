#!/bin/bash

# Dagger binary cache version resolution script
# Converts "latest" to actual version number or handles commit hashes

set -euo pipefail

DAGGER_VERSION_FILE="/tmp/.dagger-version"

# Handle commit override first
if [[ -n "${ORB_VAL_COMMIT}" ]]; then
    echo "Using Dagger dev commit: ${ORB_VAL_COMMIT}"
    echo "commit-${ORB_VAL_COMMIT}" > "$DAGGER_VERSION_FILE"
    echo "Stored Dagger version identifier: $(cat "$DAGGER_VERSION_FILE")"
    exit 0
fi

# Handle version resolution
if [[ "${ORB_VAL_VERSION}" == "latest" ]]; then
    echo "Fetching the latest Dagger version from GitHub..."
    DAGGER_LATEST_VERSION=$(curl --silent --fail --retry 6 --retry-all-errors \
        https://api.github.com/repos/dagger/dagger/releases/latest | jq -r '.tag_name') || {
        echo "Failed to fetch the latest version. Continuing with 'latest' as fallback."
        echo "latest" > "$DAGGER_VERSION_FILE"
        echo "Stored Dagger version: $(cat "$DAGGER_VERSION_FILE")"
        exit 0
    }
    echo "$DAGGER_LATEST_VERSION" > "$DAGGER_VERSION_FILE"
else
    echo "${ORB_VAL_VERSION}" > "$DAGGER_VERSION_FILE"
fi

echo "Stored Dagger version: $(cat "$DAGGER_VERSION_FILE")" 