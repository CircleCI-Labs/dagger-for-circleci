#!/bin/bash

# Dagger CLI installation script
# Uses the official Dagger install script from https://dl.dagger.io/dagger/install.sh

set -euo pipefail

# === Helper Functions ===

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

debug_log() {
    if [[ "${ORB_VAL_DEBUG}" == "true" ]]; then
        log "DEBUG: $*"
    fi
}

error_exit() {
    echo "ERROR: $*" >&2
    exit 1
}

# Check if Dagger is already installed and working
is_dagger_installed() {
    if command -v dagger >/dev/null 2>&1; then
        if dagger version >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# === Main Installation Logic ===

log "Starting Dagger CLI installation..."

# Check if we should skip installation
if [[ "${ORB_VAL_FORCE_INSTALL}" != "true" ]] && is_dagger_installed; then
    current_version=$(dagger version --format=json 2>/dev/null | jq -r '.Version' 2>/dev/null || dagger version 2>/dev/null | head -1 || echo "unknown")
    log "Dagger is already installed (version: $current_version). Use force-install=true to reinstall."
    exit 0
fi

# Prepare installation directory
# Fallback to /usr/local for backwards compatibility (following GitHub Action pattern)
prefix_dir="${RUNNER_TEMP:-/usr/local}"
# Ensure the dir is writable otherwise fallback to our specified bin-dir
if [[ ! -d "$prefix_dir" ]] || [[ ! -w "$prefix_dir" ]]; then
    prefix_dir="${ORB_VAL_BIN_DIR%/bin}"  # Remove /bin suffix if present
fi

# Create bin directory
bin_dir="$prefix_dir/bin"
mkdir -p "$bin_dir"
debug_log "Using bin directory: $bin_dir"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
    echo "export PATH=\"$bin_dir:\$PATH\"" >> "$BASH_ENV"
    export PATH="$bin_dir:$PATH"
    debug_log "Added $bin_dir to PATH"
fi

# Prepare version for install script
# If the dagger version is 'latest', set the version back to an empty
# string. This allows the install script to detect and install the latest
# version itself (following GitHub Action pattern)
VERSION="${ORB_VAL_VERSION}"
if [[ "$VERSION" == "latest" ]]; then
    VERSION=""
    debug_log "Using latest version (empty string for install script)"
else
    debug_log "Using specified version: $VERSION"
fi

COMMIT="${ORB_VAL_COMMIT}"
if [[ -n "$COMMIT" ]]; then
    debug_log "Using commit: $COMMIT"
fi

log "Downloading and running official Dagger install script..."

# Download and run the official Dagger install script
# The install.sh script creates path ${prefix_dir}/bin automatically
if ! curl -fsS https://dl.dagger.io/dagger/install.sh | \
    BIN_DIR="$bin_dir" DAGGER_VERSION="$VERSION" DAGGER_COMMIT="$COMMIT" sh; then
    error_exit "Dagger installation failed"
fi

# Verify installation
if ! command -v dagger >/dev/null 2>&1; then
    error_exit "Dagger installation failed - command not found after installation"
fi

# Test that dagger runs
if ! dagger version >/dev/null 2>&1; then
    error_exit "Dagger installation failed - unable to run 'dagger version'"
fi

# Show installed version
installed_version=$(dagger version --format=json 2>/dev/null | jq -r '.Version' 2>/dev/null || dagger version 2>/dev/null | head -1 || echo "unknown")
log "Successfully installed Dagger CLI (version: $installed_version)"

# Show installation location
log "Dagger installed at: $(which dagger)" 