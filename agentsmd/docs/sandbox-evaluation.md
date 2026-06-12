# Sandbox Environments for AI CLI Auto-Approval Workflows

## Overview

Running AI coding assistants (Claude Code, Gemini CLI) with `--dangerously-skip-permissions`
requires sandboxing to maintain security boundaries. This document evaluates available
sandbox strategies and recommends an approach for this repository.

## Executive Summary

**Recommended Approach:** Native sandbox mode (`/sandbox` in Claude Code) for macOS, combined with explicit permission deny rules.

- **Setup Complexity:** Low
- **Security Level:** Medium-High
- **Credential Management:** N/A (sandbox doesn't change auth)
- **Best For:** Development workflows on trusted machines

For higher security requirements (untrusted code execution), combine native sandboxing with Docker containers.

## Sandbox Options Evaluation

### 1. Claude Code Native Sandbox (Recommended for This Repo)

**Status:** Available now, recommended for development workflows

#### How It Works

- **macOS:** Uses built-in Seatbelt sandbox
- **Linux:** Uses [bubblewrap](https://github.com/containers/bubblewrap) for application sandboxing
- **Windows:** Filesystem virtualization (limited isolation)

#### Activation

Within Claude Code, use the `/sandbox` command to enable sandbox mode:

```text
/sandbox
```

This toggles sandbox mode for the current session. When enabled:

- Filesystem access is restricted to the project directory
- Network access restrictions may apply depending on OS
- System resource access is limited

#### Key Features

✓ **Low setup overhead** - Built into Claude Code
✓ **Full tool support** - All programming languages and tools work normally
✓ **Per-session control** - Toggle on/off as needed
✓ **macOS integration** - Uses native Seatbelt (no additional software)

#### Limitations

✗ Medium isolation level compared to containers
✗ Not suitable for executing untrusted third-party code
✗ Requires trust in the host system itself

#### Platform Notes

**macOS (Seatbelt):**

- Lightweight, built-in OS feature
- Profiles can be customized via security policies
- Good for preventing accidental filesystem damage

**Linux (bubblewrap):**

- Lightweight sandboxing with namespace isolation
- Requires bubblewrap to be installed: `sudo apt install bubblewrap`
- Stronger isolation than Seatbelt

**Windows:**

- Limited functionality compared to Unix platforms
- Recommend Docker containers for production use on Windows

### 2. Docker Desktop Sandbox (Official Claude Code Integration)

**Status:** Available in Docker Desktop 4.50+ (Experimental feature)

#### Running Docker Sandbox

```bash
docker sandbox run claude
docker sandbox run -w ~/my-project claude
```

#### Features

- **Auto-approval enabled by default** - `--dangerously-skip-permissions` not needed
- **Credential persistence** - API keys stored in Docker volume `docker-claude-sandbox-data`
- **Pre-configured tools** - GitHub CLI, Node.js, Go, Python 3, Git, ripgrep, jq
- **True isolation** - Complete container separation from host

#### Evaluation Criteria

✓ Highest isolation level
✓ Works across platforms (macOS, Linux, Windows)
✓ Official Docker + Anthropic integration
✓ Seamless credential management

✗ Requires Docker Desktop (paid for commercial use in large organizations)
✗ Slightly higher setup complexity
✗ Docker commands aren't available inside sandbox by design
✗ Performance overhead from containerization

#### Use Case

**Best for:**

- Production environments
- Untrusted code execution
- Multi-user systems
- Organizations requiring strict isolation

**Not recommended for:**

- Quick development iterations
- Trusted environments with simple tools
- Systems with limited container runtime resources

#### Credential Strategies

1. **Sandbox mode (default):** API keys persist in volume, automatic on startup
2. **None mode:** Manual authentication, no persistence between sessions

### 3. Third-Party Container Solutions

#### A. textcortex/claude-code-sandbox

**Repository:** [textcortex/claude-code-sandbox](https://github.com/textcortex/claude-code-sandbox)

```bash
docker build -t claude-sandbox .
docker run --rm -it \
  -v ~/.ssh:/root/.ssh:ro \
  -v $(pwd):/workspace \
  claude-sandbox \
  claude --dangerously-skip-permissions
```

**Security Warning:** Mounting `~/.ssh` even in read-only mode exposes private keys to the container.
For untrusted code execution, use SSH agent forwarding instead or configure Git with HTTPS authentication.

**Features:**

- Isolated branch creation (`claude/[timestamp]`)
- File copying for true isolation (not mounting)
- Web UI at `localhost:3456` with real-time commit diffs
- Automatic branch deletion on completion

**Status:** Alpha (may have security issues)
**Evaluation:** Good for experimentation; not recommended for production

#### B. rvaidya/claude-code-sandbox

**Repository:** [rvaidya/claude-code-sandbox](https://github.com/rvaidya/claude-code-sandbox)

**Features:**

- Built on asdf with 500+ tool support
- Multi-stage Docker builds with content hashing
- Dynamic tool detection from `.tool-versions`
- Incremental builds for fast iteration

**Best for:** Projects with diverse tool requirements
**Evaluation:** More complex setup, better for specialized environments

#### C. claudebox

**Repository:** [RchGrav/claudebox](https://github.com/RchGrav/claudebox)

**Features:**

- Pre-configured development profiles (C/C++, Python, Rust, Go)
- Complete project isolation
- Persistent configuration

**Best for:** Multi-language projects with standard tooling
**Evaluation:** Good balance of features and simplicity

#### D. DevContainers Integration

**Setup:**

```bash
npm install -g @devcontainers/cli
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . claude --dangerously-skip-permissions
```

**Features:**

- VS Code integration
- `.devcontainer/devcontainer.json` configuration
- Can combine with Claude native sandboxing for defense-in-depth

**Best for:** Teams using VS Code Remote Containers
**Evaluation:** Flexible but requires additional tooling

### 4. Firejail (Linux Only)

**Installation:** `sudo apt install firejail`

**Lightweight (~1MB) application sandbox** for Linux environments. Good alternative to Docker for systems without container runtime.

**Not recommended** for this repository given macOS/multiplatform requirements.

## Comparison Matrix

**Rating Scale:** ⭐ = Poor, ⭐⭐ = Fair, ⭐⭐⭐ = Good, ⭐⭐⭐⭐ = Very Good, ⭐⭐⭐⭐⭐ = Excellent

| Solution | Setup | Isolation | Platform | Credentials | Tools | Recommendation |
| -------- | ----- | --------- | -------- | ----------- | ----- | --------------- |
| Native Sandbox | ⭐⭐ | ⭐⭐⭐ | macOS/Linux/Win | N/A | Full | **Use for development** |
| Docker Sandbox | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | All | Built-in | Medium | Use for production |
| textcortex | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Docker | Manual | Medium | Experimental only |
| DevContainers | ⭐⭐⭐ | ⭐⭐⭐⭐ | Docker | Manual | High | Good for teams |
| claudebox | ⭐⭐ | ⭐⭐⭐⭐⭐ | Docker | Manual | High | Special use cases |

## Recommended Strategy for This Repository

### Primary: Native Sandbox Mode

**For development and testing:**

1. Enable native sandbox in Claude Code: `/sandbox`
2. Maintain explicit deny rules in `nix-claude-code/data/permissions/deny.nix`
3. Use for routine development tasks

**Benefits:**

- Low overhead, immediate availability
- No additional software required
- Full tool support (Docker, Node.js, etc.)
- Good for trusted development environments

**Limitations:**

- Not suitable for untrusted code
- Medium isolation (relies on OS Seatbelt/bubblewrap)

### Secondary: Docker Containers

**For production or untrusted code:**

```bash
docker sandbox run -w ~/my-project claude
```

**When to use:**

- Reviewing untrusted third-party code
- Production deployments
- CI/CD pipelines
- Multi-user systems

## Implementation: Native Sandbox Setup

### For macOS (Seatbelt)

#### Step 1: Verify Claude Code version

Check that you have the latest version of Claude Code with sandbox support.

#### Step 2: Enable sandbox in Claude Code

Within Claude Code, type:

```text
/sandbox
```

This enables sandbox mode for the current session.

#### Step 3: Maintain permission deny rules

Even with sandboxing, keep explicit deny rules for destructive patterns:

```json
{
  "permissions": [
    "Bash(rm -rf /:*)",
    "Bash(git push --force:*)"
  ]
}
```

### For Linux (bubblewrap)

#### Step 1: Install bubblewrap

```bash
sudo apt update
sudo apt install bubblewrap
```

#### Step 2: Enable sandbox mode

```text
/sandbox
```

#### Step 3: Configure deny rules

Same as macOS setup above.

### For Docker Container Alternative

#### Step 1: Install Docker Desktop

Requires Docker Desktop 4.50+ with experimental features enabled.

#### Step 2: Run Claude Code in sandbox

```bash
# Run with auto-approval in container
docker sandbox run -w ~/my-project claude

# Run with custom credentials location
docker sandbox run -w ~/my-project -c ~/.claude claude
```

#### Step 3: Manage Docker volume credentials

Credentials persist in volume:

```bash
docker volume ls | grep claude
docker volume inspect docker-claude-sandbox-data
```

## Permission Deny Rules (Defense-in-Depth)

Even with sandboxing enabled, maintain explicit deny rules for critical operations:

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

### Native Sandbox (No Special Handling)

- Credentials stored in standard locations (`~/.ssh`, `~/.config`)
- Use OS keychain for sensitive API keys
- macOS: Use `security` command with keychain
- Linux: Use `pass` or `secretstorage` packages

### Docker Sandbox (Integrated)

- API keys stored in persistent volume: `docker-claude-sandbox-data`
- Volume persists between sessions
- Configure via `-c` flag: `docker sandbox run -c ~/.claude claude`

### Best Practice: OS Keychain Integration

Store API keys in system keychain rather than files:

```bash
# macOS: Store Claude API key in keychain (prompts for password interactively)
security add-generic-password -a claude \
  -s "anthropic-api-key" -w

# Retrieve in shell
CLAUDE_API_KEY=$(security find-generic-password \
  -a claude -s "anthropic-api-key" -w 2>/dev/null)
```

## Testing Sandbox Functionality

### Test Case 1: Basic Command Execution

**Expected:** Command runs normally in sandbox

```text
/sandbox
echo "Testing sandbox isolation"
pwd
ls -la
```

### Test Case 2: Filesystem Isolation

**Expected:** Cannot access files outside project directory

```text
/sandbox
cat /etc/passwd  # Should be restricted
```

### Test Case 3: Network Access

**Expected:** Network policies apply per OS

```text
/sandbox
curl https://api.github.com  # May be restricted depending on profile
```

### Test Case 4: Git Operations

**Expected:** Git operations work normally within sandbox

```text
/sandbox
git status
git log --oneline
```

## MCP Server Compatibility

### Native Sandbox

MCP servers can run normally within native sandbox:

- File system operations scoped to project
- Network operations subject to OS sandbox policy
- Standard input/output works as expected

**Recommendation:** Test MCP servers within sandbox before production use

### Docker Sandbox

MCP servers run in container context:

- File system limited to container mount points
- Network isolated to container network
- May require explicit configuration for host communication

**Setup:** Mount project directory and configure MCP tool paths

## Migration Path for This Repository

### Phase 1: Enable Native Sandbox (Immediate)

1. Update documentation (this file)
2. Add sandbox command to quick-reference guides
3. Encourage team use of `/sandbox` for development

**Timeline:** Immediate

### Phase 2: Test Docker Sandbox (If Needed)

1. Set up Docker Desktop with experimental features
2. Test with sample projects
3. Document specific use cases

**Timeline:** When production deployment needed

### Phase 3: CI/CD Integration (Future)

1. Use Docker sandbox in GitHub Actions workflows
2. Automate credential injection via secrets
3. Set up workflow that requires sandbox for untrusted code

**Timeline:** When multi-contributor CI/CD critical

## Security Considerations

### What Sandboxing Provides

✓ **Filesystem isolation** - Limited to project directory
✓ **Resource limits** - CPU, memory constraints
✓ **Process isolation** - Own process namespace
✓ **Network restrictions** - Subject to sandbox policy

### What Sandboxing Does NOT Provide

✗ **Protection against host OS vulnerabilities** - Sandbox can be escaped with zero-days
✗ **Complete credential isolation** - Credentials may still be accessible
✗ **True multi-tenancy** - Single user per sandbox on shared system
✗ **Compliance guarantees** - Check with security team for compliance needs

### Defense-in-Depth Strategy

Combine multiple protection layers:

1. **Native sandbox** - Application-level isolation
2. **Permission deny rules** - Explicit block list
3. **Code review** - Human validation before approval
4. **Git branch protection** - Require PR reviews
5. **Audit logging** - Track all auto-approved actions

## FAQ

**Q: Will `/sandbox` mode slow down Claude Code?**
A: Minimal overhead on macOS (native Seatbelt). Linux (bubblewrap) has slightly more overhead but still acceptable.

**Q: Can I use Docker Desktop sandbox with `--dangerously-skip-permissions`?**
A: Not needed - Docker sandbox auto-enables approval by design.

**Q: Should I use native sandbox or Docker sandbox?**
A: Use native sandbox for development (faster, simpler). Use Docker for production or untrusted code.

**Q: What if I'm on Windows?**
A: Windows has limited native sandbox. Recommend Docker Desktop containers instead.

**Q: Can I combine native sandbox with Docker containers?**
A: Yes! This provides defense-in-depth. Run `docker sandbox run claude` which uses native sandboxing inside Docker.

**Q: What about credential security in native sandbox?**
A: Credentials follow normal file system rules. Use OS keychain for sensitive values rather than environment variables.

## References

- [Claude Code Sandboxing Documentation](https://code.claude.com/docs/en/sandboxing)
- [Docker AI Sandboxes - Get Started](https://docs.docker.com/ai/sandboxes/get-started/)
- [bubblewrap - Container Isolation](https://github.com/containers/bubblewrap)

## Next Steps

1. ✓ Document sandbox options (this file)
2. Test native sandbox on macOS with actual Claude Code
3. Update permission deny rules to include defense-in-depth patterns
4. Create example workflows in `.claude/workflows/` for sandbox usage
5. Add sandbox usage guide to team onboarding documentation
