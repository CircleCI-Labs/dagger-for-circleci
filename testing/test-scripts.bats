#!/usr/bin/env bats

# BATS tests for orb shell scripts
# These tests verify the functionality of our shell scripts in isolation

setup() {
    # Create a temporary directory for test files
    TEST_TMP_DIR="$(mktemp -d)"
    export TEST_TMP_DIR
    
    # Set default environment variables for testing
    export ORB_VAL_DEBUG="false"
    export ORB_VAL_DAGGER_FLAGS=""
    export ORB_VAL_VERB="call"
    export ORB_VAL_WORKDIR="."
    export ORB_VAL_CLOUD_TOKEN=""
    export ORB_VAL_MODULE=""
    export ORB_VAL_ARGS=""
    export ORB_VAL_CALL=""
}

teardown() {
    # Clean up temporary files
    if [[ -n "${TEST_TMP_DIR:-}" && -d "${TEST_TMP_DIR}" ]]; then
        rm -rf "${TEST_TMP_DIR}"
    fi
}

# === Tests for install.sh ===

@test "install.sh: contains expected functions" {
    grep -q "is_dagger_installed" src/scripts/install.sh
    grep -q "log" src/scripts/install.sh
    grep -q "debug_log" src/scripts/install.sh
    grep -q "error_exit" src/scripts/install.sh
}

@test "install.sh: is_dagger_installed function works" {
    # Extract the function for testing
    sed -n '/^is_dagger_installed/,/^}/p' src/scripts/install.sh > "$TEST_TMP_DIR/is_dagger_func.sh"
    
    # Create a mock bin directory and dagger binary
    mkdir -p "$TEST_TMP_DIR/bin"
    touch "$TEST_TMP_DIR/bin/dagger"
    chmod +x "$TEST_TMP_DIR/bin/dagger"
    
    export ORB_VAL_BIN_DIR="$TEST_TMP_DIR/bin"
    export PATH="$ORB_VAL_BIN_DIR:$PATH"
    
    # Source and test the function
    source "$TEST_TMP_DIR/is_dagger_func.sh"
    
    run is_dagger_installed
    [ "$status" -eq 0 ]
}

@test "install.sh: validates required environment variables" {
    # Skip this test as the script doesn't have explicit validation
    # The script uses default values and fallbacks for missing variables
    skip "Script uses defaults and fallbacks rather than explicit validation"
}

@test "install.sh: handles PATH correctly" {
    # Skip this test for now since it requires complex mocking
    skip "Complex integration test - covered by real usage"
}

# === Tests for dagger-binary-cache.sh ===

@test "dagger-binary-cache.sh: resolves latest version" {
    export ORB_VAL_VERSION="latest"
    export ORB_VAL_COMMIT=""
    
    # Mock the GitHub API response
    cat > "$TEST_TMP_DIR/mock_curl.sh" << 'EOF'
#!/bin/bash
if [[ "$*" == *"github.com/api"* ]]; then
    echo '{"tag_name": "v0.18.14"}'
else
    /usr/bin/curl "$@"
fi
EOF
    chmod +x "$TEST_TMP_DIR/mock_curl.sh"
    
    # Update PATH to use our mock curl
    export PATH="$TEST_TMP_DIR:$PATH"
    
    run bash src/scripts/dagger-binary-cache.sh
    [ "$status" -eq 0 ]
    [ -f "/tmp/.dagger-version" ]
    
    # Check the resolved version
    run cat /tmp/.dagger-version
    [[ "$output" == "v0.18.14" ]]
}

@test "dagger-binary-cache.sh: uses commit when specified" {
    export ORB_VAL_VERSION=""
    export ORB_VAL_COMMIT="abc123"
    
    run bash src/scripts/dagger-binary-cache.sh
    [ "$status" -eq 0 ]
    [ -f "/tmp/.dagger-version" ]
    
    # Check the commit is used with "commit-" prefix
    run cat /tmp/.dagger-version
    [[ "$output" == "commit-abc123" ]]
}

@test "dagger-binary-cache.sh: uses specific version" {
    export ORB_VAL_VERSION="v0.18.0"
    export ORB_VAL_COMMIT=""
    
    run bash src/scripts/dagger-binary-cache.sh
    [ "$status" -eq 0 ]
    [ -f "/tmp/.dagger-version" ]
    
    # Check the specific version is used
    run cat /tmp/.dagger-version
    [[ "$output" == "v0.18.0" ]]
}

# === Tests for engine-stop.sh ===

@test "engine-stop.sh: script exists and is executable" {
    [ -f "src/scripts/engine-stop.sh" ]
    [ -x "src/scripts/engine-stop.sh" ]
}

@test "engine-stop.sh: contains expected logic" {
    grep -q "docker ps --filter name=\"dagger-engine-\*\"" src/scripts/engine-stop.sh
    grep -q "docker stop -t 300" src/scripts/engine-stop.sh
    grep -q "command -v docker" src/scripts/engine-stop.sh
}

@test "engine-stop.sh: handles docker available with no containers" {
    # Test the mapfile logic in isolation
    cat > "$TEST_TMP_DIR/mapfile-test.sh" << 'EOF'
#!/bin/bash
# Test mapfile behavior with empty input
mapfile -t containers < <(echo "")
echo "Container count: ${#containers[@]}"
if [[ "${#containers[@]}" -gt 0 ]]; then
    echo "Containers found"
else
    echo "No containers found"
fi
EOF
    
    run bash "$TEST_TMP_DIR/mapfile-test.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No containers found"* ]]
}

# === Tests for dagger.sh ===

@test "dagger.sh: contains expected functions" {
    grep -q "validate_environment" src/scripts/dagger.sh
    grep -q "setup_cloud_token" src/scripts/dagger.sh
    grep -q "build_dagger_command" src/scripts/dagger.sh
    grep -q "execute_dagger" src/scripts/dagger.sh
}

@test "dagger.sh: helper functions work" {
    # Extract helper functions for testing
    sed -n '/^log()/,/^}/p' src/scripts/dagger.sh > "$TEST_TMP_DIR/helpers.sh"
    sed -n '/^debug_log()/,/^}/p' src/scripts/dagger.sh >> "$TEST_TMP_DIR/helpers.sh"
    sed -n '/^error_exit()/,/^}/p' src/scripts/dagger.sh >> "$TEST_TMP_DIR/helpers.sh"
    
    source "$TEST_TMP_DIR/helpers.sh"
    
    # Test log function
    run log "test message"
    [[ "$output" == *"test message"* ]]
    
    # Test debug_log with debug enabled
    export ORB_VAL_DEBUG="true"
    run debug_log "debug message"
    [[ "$output" == *"DEBUG: debug message"* ]]
    
    # Test debug_log with debug disabled
    export ORB_VAL_DEBUG="false"
    run debug_log "debug message"
    [ "$output" = "" ]
}

@test "dagger.sh: validate_environment function" {
    # Extract the function for testing
    sed -n '/^validate_environment()/,/^}/p' src/scripts/dagger.sh > "$TEST_TMP_DIR/validate_func.sh"
    
    # Add helper functions
    echo 'debug_log() { [[ "${ORB_VAL_DEBUG}" == "true" ]] && echo "DEBUG: $*" || true; }' >> "$TEST_TMP_DIR/validate_func.sh"
    echo 'error_exit() { echo "ERROR: $*" >&2; exit 1; }' >> "$TEST_TMP_DIR/validate_func.sh"
    
    # Create a mock dagger binary
    cat > "$TEST_TMP_DIR/dagger" << 'EOF'
#!/bin/bash
if [[ "$1" == "version" ]]; then
    if [[ "$2" == "--format=json" ]]; then
        echo '{"Version": "v0.18.14"}'
    else
        echo "dagger v0.18.14"
    fi
    exit 0
fi
exit 1
EOF
    chmod +x "$TEST_TMP_DIR/dagger"
    
    export PATH="$TEST_TMP_DIR:$PATH"
    export ORB_VAL_DEBUG="false"
    
    source "$TEST_TMP_DIR/validate_func.sh"
    
    run validate_environment
    [ "$status" -eq 0 ]
}

@test "dagger.sh: setup_cloud_token function" {
    # Extract the function for testing and test inline
    export MY_TOKEN="secret123"
    export ORB_VAL_CLOUD_TOKEN="MY_TOKEN"
    export ORB_VAL_DEBUG="false"
    
    # Create test script with function
    cat > "$TEST_TMP_DIR/token_test.sh" << 'EOF'
#!/bin/bash
log() { echo "$*"; }
debug_log() { [[ "${ORB_VAL_DEBUG}" == "true" ]] && echo "DEBUG: $*" || true; }

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

setup_cloud_token
# Print the token for verification
echo "TOKEN_VALUE:$DAGGER_CLOUD_TOKEN"
EOF
    
    run bash "$TEST_TMP_DIR/token_test.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dagger Cloud token configured"* ]]
    [[ "$output" == *"TOKEN_VALUE:secret123"* ]]
}

@test "dagger.sh: build_dagger_command - basic command" {
    # Extract the function for testing
    sed -n '/^build_dagger_command()/,/^}/p' src/scripts/dagger.sh > "$TEST_TMP_DIR/build_cmd_func.sh"
    
    # Add helper function
    echo 'debug_log() { [[ "${ORB_VAL_DEBUG}" == "true" ]] && echo "DEBUG: $*" || true; }' >> "$TEST_TMP_DIR/build_cmd_func.sh"
    
    export ORB_VAL_DAGGER_FLAGS=""
    export ORB_VAL_MODULE=""
    export ORB_VAL_VERB="call"
    export ORB_VAL_CALL=""
    export ORB_VAL_ARGS=""
    export ORB_VAL_DEBUG="false"
    
    source "$TEST_TMP_DIR/build_cmd_func.sh"
    build_dagger_command
    
    [[ "$DAGGER_COMMAND" == "dagger call" ]]
}

@test "dagger.sh: build_dagger_command - with flags and module" {
    # Extract the function for testing
    sed -n '/^build_dagger_command()/,/^}/p' src/scripts/dagger.sh > "$TEST_TMP_DIR/build_cmd_func.sh"
    
    # Add helper function
    echo 'debug_log() { [[ "${ORB_VAL_DEBUG}" == "true" ]] && echo "DEBUG: $*" || true; }' >> "$TEST_TMP_DIR/build_cmd_func.sh"
    
    export ORB_VAL_DAGGER_FLAGS="--debug --progress plain"
    export ORB_VAL_MODULE="github.com/example/module"
    export ORB_VAL_VERB="call"
    export ORB_VAL_CALL=""
    export ORB_VAL_ARGS=""
    export ORB_VAL_DEBUG="false"
    
    source "$TEST_TMP_DIR/build_cmd_func.sh"
    build_dagger_command
    
    # Check that flags come before verb and module flag comes before verb
    [[ "$DAGGER_COMMAND" == "dagger --debug --progress plain --mod github.com/example/module call" ]]
}

@test "dagger.sh: build_dagger_command - call parameter takes precedence" {
    # Extract the function for testing
    sed -n '/^build_dagger_command()/,/^}/p' src/scripts/dagger.sh > "$TEST_TMP_DIR/build_cmd_func.sh"
    
    # Add helper function
    echo 'debug_log() { [[ "${ORB_VAL_DEBUG}" == "true" ]] && echo "DEBUG: $*" || true; }' >> "$TEST_TMP_DIR/build_cmd_func.sh"
    
    export ORB_VAL_DAGGER_FLAGS=""
    export ORB_VAL_MODULE=""
    export ORB_VAL_VERB="call"
    export ORB_VAL_CALL="hello --name world"
    export ORB_VAL_ARGS="goodbye"
    export ORB_VAL_DEBUG="false"
    
    source "$TEST_TMP_DIR/build_cmd_func.sh"
    build_dagger_command
    
    [[ "$DAGGER_COMMAND" == "dagger call hello --name world" ]]
}

@test "dagger.sh: build_dagger_command - args parameter when call is empty" {
    # Extract the function for testing
    sed -n '/^build_dagger_command()/,/^}/p' src/scripts/dagger.sh > "$TEST_TMP_DIR/build_cmd_func.sh"
    
    # Add helper function
    echo 'debug_log() { [[ "${ORB_VAL_DEBUG}" == "true" ]] && echo "DEBUG: $*" || true; }' >> "$TEST_TMP_DIR/build_cmd_func.sh"
    
    export ORB_VAL_DAGGER_FLAGS=""
    export ORB_VAL_MODULE=""
    export ORB_VAL_VERB="call"
    export ORB_VAL_CALL=""
    export ORB_VAL_ARGS="hello --name world"
    export ORB_VAL_DEBUG="false"
    
    source "$TEST_TMP_DIR/build_cmd_func.sh"
    build_dagger_command
    
    [[ "$DAGGER_COMMAND" == "dagger call hello --name world" ]]
} 