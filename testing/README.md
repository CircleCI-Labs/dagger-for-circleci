# Testing Guide for Dagger CircleCI Orb

This directory contains testing tools for the Dagger CircleCI orb. All tests run locally using standard CLI tools.

## Prerequisites

Install the required testing tools:

- **yamllint**: `pip install yamllint` or `brew install yamllint`
- **shellcheck**: `brew install shellcheck` or `apt-get install shellcheck`
- **bats**: `brew install bats-core` or `npm install -g bats`
- **yq**: `brew install yq` or [install from releases](https://github.com/mikefarah/yq/releases)
- **jq**: `brew install jq` or `apt-get install jq`
- **CircleCI CLI**: [Install the CircleCI CLI](https://circleci.com/docs/local-cli/) (for orb packing and validation)

## Quick Test Commands

### Run All Tests (Recommended)
```bash
./testing/run-all-tests.sh
```

### Individual Tests
```bash
# YAML Linting
yamllint src/

# Orb Structure Review (BATS tests)
bats testing/review.bats

# Shell Script Unit Tests (BATS tests)
bats testing/test-scripts.bats

# Shell Script Validation  
shellcheck src/scripts/*.sh

# Orb Packing Test
./testing/pack-orb.sh
```

## Test Details

### 1. YAML Linting
Validates all YAML files in the `src/` directory using yamllint with CircleCI-specific rules.

### 2. Orb Review Tests
Runs the official CircleCI orb review tests using BATS:
- RC001: Include source_url in @orb.yml
- RC002: All components must have descriptions
- RC003: At least one usage example required
- RC004: Descriptive example names
- RC005: Detailed orb description (64+ chars)
- RC006: Valid source URL
- RC007: Valid home URL (if present)
- RC008: All run steps should have names
- RC009: Complex commands should use include syntax
- RC010: Components should be snake_cased

### 3. Shell Script Unit Tests
Tests our shell scripts with isolated unit tests:
- Helper function testing (log, debug_log, error_exit)
- Function isolation and mocking
- Version resolution logic
- PATH handling
- Environment variable validation
- Cache handling logic

### 4. Shell Script Validation
Uses shellcheck to validate all shell scripts in `src/scripts/`.

### 5. Orb Packing
Tests that the orb can be successfully packed using the CircleCI CLI.

## Pre-Push Checklist

Before pushing any code:
- [ ] All tests pass (`./testing/run-all-tests.sh`)
- [ ] No linting errors in YAML files
- [ ] All shell scripts pass shellcheck
- [ ] Orb review tests pass
- [ ] Shell script unit tests pass
- [ ] Orb packs successfully
- [ ] Get approval before pushing

## Troubleshooting

**Missing tools**: Install all prerequisites listed above
**YAML errors**: Check indentation and syntax in src/ files  
**Shell errors**: Review shellcheck suggestions for shell scripts
**Review test failures**: Address specific RC### test failures shown in output
**Packing failures**: Check orb structure and CircleCI CLI installation
**Unit test failures**: Check isolated function logic and mocking setup 