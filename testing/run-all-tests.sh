#!/bin/bash

set -euo pipefail

echo "########################################"
echo "# Dagger CircleCI Orb - Test Suite    #"
echo "########################################"
echo ""

# Track test results
failed_tests=()
passed_tests=()

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_script="$2"
    
    echo "Running: $test_name"
    echo "---"
    
    if eval "$test_script"; then
        echo "PASSED: $test_name"
        passed_tests+=("$test_name")
    else
        echo "FAILED: $test_name"
        failed_tests+=("$test_name")
    fi
    echo ""
}

# Check prerequisites
echo "Checking prerequisites..."

# Check required tools
missing_tools=()

if ! command -v yamllint &> /dev/null; then
    missing_tools+=("yamllint")
fi

if ! command -v shellcheck &> /dev/null; then
    missing_tools+=("shellcheck")
fi

if ! command -v bats &> /dev/null; then
    missing_tools+=("bats")
fi

if ! command -v yq &> /dev/null; then
    missing_tools+=("yq")
fi

if ! command -v jq &> /dev/null; then
    missing_tools+=("jq")
fi

if ! command -v circleci &> /dev/null; then
    missing_tools+=("circleci")
fi

if [ ${#missing_tools[@]} -ne 0 ]; then
    echo "ERROR: Missing required tools: ${missing_tools[*]}"
    echo "Please install them and try again. See testing/README.md for instructions."
    exit 1
fi

echo "All prerequisites found."
echo ""

# Make all test scripts executable
chmod +x testing/*.sh

# Run all tests
echo "Starting test suite..."
echo ""

run_test "YAML Linting" "yamllint src/"
run_test "Orb Review Tests" "bats testing/review.bats"
run_test "Shell Script Tests" "bats testing/test-scripts.bats"
run_test "Shell Script Validation" "shellcheck src/scripts/*.sh"
run_test "Orb Packing Test" "./testing/pack-orb.sh"

# Summary
echo "####################################"
echo "# Test Summary"
echo "####################################"
echo ""

if [ ${#passed_tests[@]} -gt 0 ]; then
    echo "PASSED Tests (${#passed_tests[@]}):"
    for test in "${passed_tests[@]}"; do
        echo "  - $test"
    done
    echo ""
fi

if [ ${#failed_tests[@]} -gt 0 ]; then
    echo "FAILED Tests (${#failed_tests[@]}):"
    for test in "${failed_tests[@]}"; do
        echo "  - $test"
    done
    echo ""
    echo "Please fix the failing tests before pushing code."
    exit 1
else
    echo "SUCCESS: All tests passed!"
    echo "Your orb is ready for code review."
fi 