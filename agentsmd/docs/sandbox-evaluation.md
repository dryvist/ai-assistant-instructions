# Sandbox Environments for AI CLI Auto-Approval Workflows

## Overview

Running AI coding assistants (Claude Code, Gemini CLI) with `--dangerously-skip-permissions`
requires sandboxing to keep security boundaries intact. This doc compares the available approaches
and recommends a default for this repository.

## Executive Summary

**Recommended Approach:** Native sandbox mode (`/sandbox` in Claude Code) on macOS, plus explicit permission deny rules.

- **Setup Complexity:** Low
- **Security Level:** Medium-high
- **Credential Management:** N/A (sandbox does not change auth)
- **Best For:** Trusted development workflows

For higher isolation or untrusted code execution, use Docker containers.

## Sandbox Options Evaluation

### 1. Claude Code Native Sandbox (Recommended for This Repo)

**Status:** Available now and recommended for development workflows.

#### How It Works

- **macOS:** Uses the built-in Seatbelt sandbox
- **Linux:** Uses [bubblewrap](https://github.com/containers/bubblewrap) for application sandboxing
- **Windows:** Uses filesystem virtualization with limited isolation

#### Activation

Within Claude Code, enable sandbox mode with:

```text
/sandbox
```

This toggles sandbox mode for the current session. When enabled:

- Filesystem access stays within the project directory
- Network access depends on the OS profile
- System resource limits apply

#### Key Features

- Low setup overhead
- Full tool support
- Per-session control
- Native macOS integration

#### Limits

- Medium isolation compared with containers
- Not suitable for untrusted third-party code
- Depends on trust in the host OS

#### Platform Notes

- **macOS:** Lightweight, built-in, and good at preventing accidental filesystem damage
- **Linux:** Namespace isolation, requires `sudo apt install bubblewrap`, stronger than Seatbelt
- **Windows:** Limited; prefer Docker containers

### 2. Docker Desktop Sandbox (Official Claude Code Integration)

**Status:** Available in Docker Desktop 4.50+ as an experimental feature.

#### Running Docker Sandbox

```bash
docker sandbox run claude
docker sandbox run -w ~/my-project claude
```

#### Features

- Auto-approval by default; `--dangerously-skip-permissions` is not needed
- API keys stored in persistent `docker-claude-sandbox-data`
- Pre-configured tools: GitHub CLI, Node.js, Go, Python 3, Git, ripgrep, jq
- Strong isolation

#### Tradeoffs

- Highest isolation
- Works across macOS, Linux, and Windows
- Official Docker + Anthropic integration
- Requires Docker Desktop and adds setup/runtime overhead

#### Use Case

- Production environments
- Untrusted code execution
- Multi-user systems
- CI/CD

#### Credential Strategies

1. **Sandbox mode:** API keys persist in the Docker volume
2. **None mode:** Manual auth, no persistence between sessions

### 3. Other Container Wrappers

`textcortex/claude-code-sandbox`, `rvaidya/claude-code-sandbox`, `claudebox`, and DevContainers
are worth knowing about, but they add complexity and are not the default path for this repo.

### 4. Firejail (Linux Only)

Firejail is a lightweight Linux application sandbox. It is not recommended here because this repo targets macOS and multiplatform workflows.

## Recommended Strategy for This Repository

### Primary: Native Sandbox Mode

For development and testing:

1. Enable native sandbox in Claude Code with `/sandbox`.
2. Keep explicit deny rules in `nix-claude-code/data/permissions/deny.nix`.
3. Use it for routine development tasks.

Benefits: low overhead, no extra software, full tool support, good fit for trusted development.
Limits: not for untrusted code; isolation is medium.

### Secondary: Docker Containers

Use `docker sandbox run -w ~/my-project claude` when you need stricter isolation for untrusted code, production deployments, CI/CD, or multi-user systems.

## Implementation: Native Sandbox Setup

### For macOS (Seatbelt)

1. Verify Claude Code has sandbox support.
2. Enable sandbox with `/sandbox`.
3. Keep permission deny rules in place.

### For Linux (bubblewrap)

1. Install bubblewrap.
2. Enable sandbox with `/sandbox`.
3. Configure the same deny rules.

### For Docker Container Alternative

1. Install Docker Desktop 4.50+ with experimental features enabled.
2. Run Claude Code in sandbox:

```bash
docker sandbox run -w ~/my-project claude
docker sandbox run -w ~/my-project -c ~/.claude claude
```

3. Credentials persist in `docker-claude-sandbox-data`.

## Permission Deny Rules (Defense-in-Depth)

Even with sandboxing enabled, keep explicit deny rules for critical operations:

**File: `nix-claude-code/data/permissions/deny.nix`**

```json
{
  "permissions": [
    "Bash(rm -rf /:*)",
    "Bash(rm -rf ~:*)",
    "Bash(rm -fr /:*)",
    "Bash(rm -fr ~:*)",
    "Bash(rm --recursive --force /:*)",
    "Bash(rm --recursive --force ~:*)",
    "Bash(git push --force:*)",
    "Bash(git push -f:*)",
    "Bash(sudo dd:*)",
    "Bash(dd if=:*)"
  ]
}
```

## Credential Management in Sandboxes

- Native sandbox: credentials use normal file-system paths; store sensitive API keys in the OS keychain instead of files.
- Docker sandbox: API keys persist in `docker-claude-sandbox-data`; use `-c ~/.claude` if you want Claude config mounted.
- Best practice on macOS:

```bash
security add-generic-password -a claude \
  -s "anthropic-api-key" -w
CLAUDE_API_KEY=$(security find-generic-password \
  -a claude -s "anthropic-api-key" -w 2>/dev/null)
```

## Smoke Tests

- `/sandbox`; `echo`, `pwd`, `ls -la`
- `cat /etc/passwd` should stay blocked
- `curl https://api.github.com` should follow the sandbox policy
- `git status` and `git log --oneline` should still work

## MCP Server Compatibility

- Native sandbox: MCP servers can run normally; filesystem access stays within the project and network access follows the sandbox policy.
- Docker sandbox: MCP servers run in the container and are limited to its mounts and network.

## Security Considerations

### What Sandboxing Provides

- Filesystem isolation limited to the project directory or container mount
- Resource limits
- Process isolation
- Network restrictions subject to the active profile

### What Sandboxing Does Not Provide

- Protection against host OS vulnerabilities
- Complete credential isolation
- True multi-tenancy
- Compliance guarantees

### Defense-in-Depth Strategy

1. Native sandbox
2. Permission deny rules
3. Code review
4. Git branch protection
5. Audit logging
