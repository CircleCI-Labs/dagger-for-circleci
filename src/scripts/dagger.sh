#!/bin/bash

# Dagger CLI execution script
# Self-contained script for executing Dagger commands with full parameter support

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

# Validate required tools
validate_environment() {
    if ! command -v dagger >/dev/null 2>&1; then
        error_exit "Dagger CLI not found. Please install Dagger first using the install command."
    fi
    
    debug_log "Dagger CLI found at: $(which dagger)"
    
    # Test that dagger runs
    if ! dagger version >/dev/null 2>&1; then
        error_exit "Dagger CLI is installed but not working. Please check your installation."
    fi
    
    local dagger_version
    dagger_version=$(dagger version --format=json 2>/dev/null | jq -r '.Version' 2>/dev/null || dagger version 2>/dev/null | head -1 || echo "unknown")
    debug_log "Using Dagger version: $dagger_version"
}

# Setup Dagger Cloud token if provided
setup_cloud_token() {
    if [[ -n "${ORB_VAL_CLOUD_TOKEN}" ]]; then
        if [[ -n "${!ORB_VAL_CLOUD_TOKEN:-}" ]]; then
            export DAGGER_CLOUD_TOKEN="${!ORB_VAL_CLOUD_TOKEN}"
            log "Dagger Cloud token configured"
            debug_log "Cloud token environment variable: $ORB_VAL_CLOUD_TOKEN"
        else
            log "Warning: Cloud token environment variable '$ORB_VAL_CLOUD_TOKEN' is not set"
        fi
    fi
}

# Build the dagger command
# shellcheck disable=SC2120  # We use eval to set positional parameters locally
build_dagger_command() {
    local cmd_parts=()
    
    # Start with dagger
    cmd_parts+=("dagger")
    
    # Add global flags BEFORE verb
    if [[ -n "${ORB_VAL_DAGGER_FLAGS}" ]]; then
        # Split flags by spaces and add each one
        read -ra FLAGS <<< "${ORB_VAL_DAGGER_FLAGS}"
        for flag in "${FLAGS[@]}"; do
            cmd_parts+=("$flag")
        done
    fi
    
    # Add module flag BEFORE verb if specified
    if [[ -n "${ORB_VAL_MODULE}" ]]; then
        cmd_parts+=("--mod" "${ORB_VAL_MODULE}")
    fi
    
    # Add the verb
    cmd_parts+=("${ORB_VAL_VERB}")
    
    # Handle args vs call parameter (call takes precedence as it's an alias)
    local cli_args=""
    if [[ -n "${ORB_VAL_CALL}" ]]; then
        cli_args="${ORB_VAL_CALL}"
        debug_log "Using 'call' parameter: $cli_args"
    elif [[ -n "${ORB_VAL_ARGS}" ]]; then
        cli_args="${ORB_VAL_ARGS}"
        debug_log "Using 'args' parameter: $cli_args"
    fi
    
    # Add CLI arguments if provided
    if [[ -n "$cli_args" ]]; then
        # Use eval to properly handle quoted arguments
        # shellcheck disable=SC2086  # We intentionally want word splitting here
        eval "set -- $cli_args"
        for arg in "$@"; do
            cmd_parts+=("$arg")
        done
    fi
    
    # Export the command for later use
    printf -v DAGGER_COMMAND '%q ' "${cmd_parts[@]}"
    DAGGER_COMMAND=${DAGGER_COMMAND% }  # Remove trailing space
    export DAGGER_COMMAND
    
    debug_log "Built command: $DAGGER_COMMAND"
}

# Execute the dagger command
execute_dagger() {
    local original_dir
    original_dir=$(pwd)
    
    # Change to working directory if specified
    if [[ "${ORB_VAL_WORKDIR}" != "." ]]; then
        if [[ ! -d "${ORB_VAL_WORKDIR}" ]]; then
            error_exit "Working directory '${ORB_VAL_WORKDIR}' does not exist"
        fi
        cd "${ORB_VAL_WORKDIR}"
        log "Changed to working directory: ${ORB_VAL_WORKDIR}"
    fi
    
    log "Executing: $DAGGER_COMMAND"
    
    # Execute the command
    if eval "$DAGGER_COMMAND"; then
        log "Dagger command completed successfully"
    else
        local exit_code=$?
        error_exit "Dagger command failed with exit code: $exit_code"
    fi
    
    # Return to original directory
    cd "$original_dir"
}

# === Main Execution Logic ===

log "Starting Dagger execution..."

# Validate environment
validate_environment

# Setup cloud token
setup_cloud_token

# Build the command
build_dagger_command

# Execute the command
execute_dagger

log "Dagger execution completed successfully" 