# Dagger CircleCI Orb

[![CircleCI Build Status](https://circleci.com/gh/98KhFjn8YyZY9qoBGmzCBs/dagger-for-circleci.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/98KhFjn8YyZY9qoBGmzCBs/dagger-for-circleci) [![CircleCI Orb Version](https://badges.circleci.com/orbs/cci-labs/dagger-for-circleci.svg)](https://circleci.com/developer/orbs/orb/cci-labs/dagger-for-circleci) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/98KhFjn8YyZY9qoBGmzCBs/dagger-for-circleci/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)

A CircleCI orb for integrating [Dagger](https://dagger.io/) workflows into your CI/CD pipelines. This orb provides the same functionality as the [official Dagger GitHub Action](https://github.com/dagger/dagger-for-github) with full parameter compatibility.

## Features

- **GitHub Action Parity**: All parameters and functionality match the official Dagger GitHub Action
- **Easy Installation**: Automated Dagger CLI installation with version management  
- **Flexible Execution**: Support for all Dagger CLI verbs (call, run, download, etc.)
- **Cloud Integration**: Built-in support for Dagger Cloud tokens
- **CircleCI Optimized**: Leverages CircleCI caching and workspace features
- **Smart Caching**: Intelligent CLI caching to speed up builds
- **Engine Management**: Automatic Dagger Engine lifecycle management

## Quick Start

### Simple Dagger Call

```yaml
version: 2.1

orbs:
  dagger: cci-labs/dagger-for-circleci@1.0.0

workflows:
  hello:
    jobs:
      - dagger/dagger:
          version: "latest"
          module: "github.com/shykes/daggerverse/hello" 
          call: "hello --greeting Hola --name Jeremy"
          cloud_token: "DAGGER_CLOUD_TOKEN"
```

### Dagger Run Command

```yaml
version: 2.1

orbs:
  dagger: cci-labs/dagger-for-circleci@1.0.0

workflows:
  build:
    jobs:
      - dagger/dagger:
          version: "latest"
          verb: "run"
          args: "node build.js"
          workdir: "api"
          cloud_token: "DAGGER_CLOUD_TOKEN"
```

## Commands

### `install`

Installs the Dagger CLI with version management and caching support.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `version` | string | `"latest"` | The version of Dagger to install |
| `debug` | boolean | `false` | Enable debug logging for installing Dagger |
| `bin_dir` | string | `"/home/circleci/bin"` | The directory where Dagger should be installed |
| `force_install` | boolean | `false` | Force install Dagger if already present |
| `cache_cli` | boolean | `true` | Enables caching of Dagger CLI using CircleCI caching |
| `cache_key_prefix` | string | `"v1"` | Prefixes a string to all cache keys |
| `commit` | string | `""` | Dagger dev commit (overrides version) |

#### Example

```yaml
steps:
  - dagger/install:
      version: "latest"
      cache_cli: true
      debug: true
```

### `dagger`

Executes Dagger CLI commands with full parameter support, including automatic installation.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `version` | string | `"latest"` | Dagger version (auto-install if specified and not already installed) |
| `commit` | string | `""` | Dagger dev commit (overrides version) |
| `bin_dir` | string | `"/home/circleci/bin"` | Installation directory for Dagger binary |
| `cache_cli` | boolean | `true` | Enable CLI caching |
| `cache_key_prefix` | string | `"v1"` | Cache key prefix for CLI caching |
| `force_install` | boolean | `false` | Force installation even if Dagger is already present |
| `dagger_flags` | string | `"--progress plain"` | Dagger CLI flags |
| `verb` | string | `"call"` | CLI verb (call, run, download, up, functions, shell, query) |
| `workdir` | string | `"."` | Working directory |
| `cloud_token` | env_var_name | `"DAGGER_CLOUD_TOKEN"` | Dagger Cloud Token environment variable |
| `module` | string | `""` | Dagger module to call (local or Git) |
| `args` | string | `""` | Arguments to pass to CLI |
| `call` | string | `""` | Arguments to pass to CLI (alias for args) |
| `engine_stop` | boolean | `true` | Whether to stop Dagger Engine |
| `debug` | boolean | `false` | Enable debug logging for Dagger execution |

#### Example

```yaml
steps:
  - dagger/dagger:
      verb: "call"
      module: "./ci"
      call: "test --verbose"
      cloud_token: "DAGGER_CLOUD_TOKEN"
      debug: true
```

### `cache_cli`

Cache Dagger CLI for faster subsequent builds.

> **Note**: This command is typically used internally by the `install` command when `cache_cli: true` is set. Most users should not need to use this command directly.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `bin_dir` | string | `"/home/circleci/bin"` | The directory where Dagger should be installed |
| `cache_key_prefix` | string | `"v1"` | Prefixes a string to all cache keys |

#### Example

```yaml
steps:
  - dagger/cache_cli:
      bin_dir: "/usr/local/bin"
      cache_key_prefix: "dagger-v2"
```

### `restore_cli`

Restore cached Dagger CLI from previous builds.

> **Note**: This command is typically used internally by the `install` command when `cache_cli: true` is set. Most users should not need to use this command directly.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `version` | string | `"latest"` | The version of Dagger to install |
| `commit` | string | `""` | Dagger dev commit (overrides version) |
| `cache_key_prefix` | string | `"v1"` | Prefixes a string to all cache keys |

#### Example

```yaml
steps:
  - dagger/restore_cli:
      version: "0.9.3"
      cache_key_prefix: "dagger-v2"
```

## Jobs

### `dagger`

Complete job that installs Dagger and executes the specified command.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `executor` | executor | `default` | Executor to use for the job |
| `checkout` | boolean | `true` | Enable checkout step |
| `version` | string | `"latest"` | Dagger version (auto-install if specified and not already installed) |
| `commit` | string | `""` | Dagger dev commit (overrides version) |
| `bin_dir` | string | `"/home/circleci/bin"` | Installation directory for Dagger binary |
| `cache_cli` | boolean | `true` | Enable CLI caching |
| `cache_key_prefix` | string | `"v1"` | Cache key prefix for CLI caching |
| `force_install` | boolean | `false` | Force installation even if Dagger is already present |
| `dagger_flags` | string | `"--progress plain"` | Dagger CLI flags |
| `verb` | string | `"call"` | CLI verb (call, run, download, up, functions, shell, query) |
| `workdir` | string | `"."` | Working directory |
| `cloud_token` | env_var_name | `"DAGGER_CLOUD_TOKEN"` | Dagger Cloud Token environment variable |
| `module` | string | `""` | Dagger module to call (local or Git) |
| `args` | string | `""` | Arguments to pass to CLI |
| `call` | string | `""` | Arguments to pass to CLI (alias for args) |
| `engine_stop` | boolean | `true` | Whether to stop Dagger Engine |
| `debug` | boolean | `false` | Enable debug logging for Dagger execution |

#### Example

```yaml
workflows:
  ci:
    jobs:
      - dagger/dagger:
          version: "latest"
          module: "github.com/dagger/dagger"
          call: "test"
          checkout: false  # Skip checkout if already done
          cloud_token: "DAGGER_CLOUD_TOKEN"
```

## Executors

### `default`

Default Linux machine executor optimized for Dagger workflows.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `tag` | string | `"current"` | The tag for the Ubuntu machine image |
| `resource_class` | string | `"medium"` | The resource class for the executor (e.g., small, medium, large, xlarge) |
| `docker_layer_caching` | boolean | `false` | Enable Docker Layer Caching to speed up Docker builds |

#### Default Configuration

- **Image**: `ubuntu-2404:current`
- **Resource Class**: `medium`
- **Docker Layer Caching**: `false`
- **Environment**: Linux machine with Docker support

## Advanced Usage Examples

### Multi-Step Workflow

```yaml
version: 2.1

orbs:
  dagger: cci-labs/dagger-for-circleci@1.0.0

jobs:
  ci-pipeline:
    executor: dagger/default
    steps:
      - checkout
      - dagger/install:
          version: "latest"
          cache_cli: true
      - dagger/dagger:
          verb: "call"
          module: "./ci"
          call: "lint"
      - dagger/dagger:
          verb: "call"
          module: "./ci"
          call: "test --coverage"
      - dagger/dagger:
          verb: "call"
          module: "./ci"
          call: "build --platform linux/amd64,linux/arm64"
          cloud_token: "DAGGER_CLOUD_TOKEN"

workflows:
  main:
    jobs:
      - ci-pipeline
```

### Using Different Dagger Verbs

```yaml
# Run commands in Dagger session
- dagger/dagger:
    verb: "run"
    args: "go test ./..."

# Query Dagger functions
- dagger/dagger:
    verb: "functions"
    module: "./ci"

# Call with custom working directory
- dagger/dagger:
    verb: "call"
    module: "./backend"
    call: "build --env production"
    workdir: "services/api"
```

### Manual Cache Management

```yaml
steps:
  - checkout
  - dagger/restore_cli:
      version: "0.9.3"
      cache_key_prefix: "custom-cache"
  - dagger/install:
      version: "0.9.3"
      cache_cli: false  # Skip auto-caching
  - dagger/dagger:
      verb: "call"
      module: "./ci"
      call: "build"
  - dagger/cache_cli:
      cache_key_prefix: "custom-cache"
```

## Migration from GitHub Actions

If you're migrating from the [Dagger GitHub Action](https://github.com/dagger/dagger-for-github), the parameter mapping is:

| GitHub Action | CircleCI Orb | Notes |
|---------------|--------------|-------|
| `version` | `version` | Exact same |
| `commit` | `commit` | Exact same |
| `dagger-flags` | `dagger_flags` | Snake case in CircleCI |
| `verb` | `verb` | Exact same |
| `workdir` | `workdir` | Exact same |
| `cloud-token` | `cloud_token` | Snake case in CircleCI |
| `module` | `module` | Exact same |
| `args` | `args` | Exact same |
| `call` | `call` | Exact same |
| `engine-stop` | `engine_stop` | Snake case in CircleCI |

## Error Handling

The orb includes comprehensive error handling:

- **Installation Errors**: Automatic retry and fallback mechanisms
- **Version Validation**: Validates Dagger version format
- **Network Issues**: Graceful handling of download failures
- **Permission Problems**: Clear error messages for access issues
- **Command Failures**: Detailed logging of Dagger CLI errors

## Troubleshooting

### Common Issues

1. **Dagger not found**: Ensure `version` parameter is set for auto-installation
2. **Permission denied**: Use appropriate `resource_class` for installation
3. **Network timeouts**: Enable `debug: true` for detailed logging
4. **Cache issues**: Set `force_install: true` to bypass cache

### Debug Mode

Enable debug logging for troubleshooting:

```yaml
- dagger/dagger:
    verb: "call"
    module: "./ci"
    call: "build"
    debug: true  # Enables verbose logging
```

## Development

### Testing

This orb includes comprehensive testing tools in the [`testing/`](testing/) directory. Before contributing:

1. Install the [CircleCI CLI](https://circleci.com/docs/local-cli/)
2. Run the test suite: `./testing/run-all-tests.sh`
3. Ensure all tests pass before submitting pull requests

For detailed testing instructions, see [testing/README.md](testing/README.md).

---

## Resources

[CircleCI Orb Registry Page](https://circleci.com/developer/orbs/orb/cci-labs/dagger-for-circleci) - The official registry page of this orb for all versions, executors, commands, and jobs described.

[CircleCI Orb Docs](https://circleci.com/docs/orb-intro/#section=configuration) - Docs for using, creating, and publishing CircleCI Orbs.

[Dagger Documentation](https://docs.dagger.io/) - Official Dagger documentation and guides.

### How to Contribute

We welcome [issues](https://github.com/98KhFjn8YyZY9qoBGmzCBs/dagger-for-circleci/issues) to and [pull requests](https://github.com/98KhFjn8YyZY9qoBGmzCBs/dagger-for-circleci/pulls) against this repository!

**Before contributing:**
- Run the test suite in the `testing/` directory
- Ensure all tests pass
- Follow CircleCI orb best practices

### How to Publish An Update
1. Merge pull requests with desired changes to the main branch.
    - For the best experience, squash-and-merge and use [Conventional Commit Messages](https://conventionalcommits.org/).
2. Find the current version of the orb.
    - You can run `circleci orb info cci-labs/dagger-for-circleci | grep "Latest"` to see the current version.
3. Create a [new Release](https://github.com/98KhFjn8YyZY9qoBGmzCBs/dagger-for-circleci/releases/new) on GitHub.
    - Click "Choose a tag" and _create_ a new [semantically versioned](http://semver.org/) tag. (ex: v1.0.0)
      - We will have an opportunity to change this before we publish if needed after the next step.
4.  Click _"+ Auto-generate release notes"_.
    - This will create a summary of all of the merged pull requests since the previous release.
    - If you have used _[Conventional Commit Messages](https://conventionalcommits.org/)_ it will be easy to determine what types of changes were made, allowing you to ensure the correct version tag is being published.
5. Now ensure the version tag selected is semantically accurate based on the changes included.
6. Click _"Publish Release"_.
    - This will push a new tag and trigger your publishing pipeline on CircleCI.

### Development Orbs

Prerequisites:

- An initial sevmer deployment must be performed in order for Development orbs to be published and seen in the [Orb Registry](https://circleci.com/developer/orbs).

A [Development orb](https://circleci.com/docs/orb-concepts/#development-orbs) can be created to help with rapid development or testing. To create a Development orb, change the `orb-tools/publish` job in `test-deploy.yml` to be the following:

```yaml
- orb-tools/publish:
    orb_name: cci-labs/dagger-for-circleci
    vcs_type: << pipeline.project.type >>
    pub_type: dev
    # Ensure this job requires all test jobs and the pack job.
    requires:
      - orb-tools/pack
      - command-test
    context: orb-publishing
    filters: *filters
```

The job output will contain a link to the Development orb Registry page. The parameters `enable_pr_comment` and `github_token` can be set to add the relevant publishing information onto a pull request. Please refer to the [orb-tools/publish](https://circleci.com/developer/orbs/orb/circleci/orb-tools#jobs-publish) documentation for more information and options.
