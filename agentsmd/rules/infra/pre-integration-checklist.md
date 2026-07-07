---
name: pre-integration-checklist
description: Pre-integration checklist for new local inference backends (MLX, vLLM, etc.)
paths:
  - "flake.nix"
  - "**/nix-*/**"
  - "**/terraform-*/**"
  - "**/ansible-*/**"
  - "**/mlx*"
  - "**/vllm*"
---

# Pre-Integration Checklist for New Inference Backends

Complete every item before merging a new inference backend (MLX (vllm-mlx), vLLM, etc.).

## Memory Budget

- [ ] Document peak RAM usage for the largest model you plan to serve
- [ ] Document sustained (idle-loaded) RAM usage with a model resident
- [ ] Verify total system RAM can handle the backend plus normal workload (browser, IDE, Claude Code)
- [ ] Set an explicit memory ceiling in the LaunchAgent or service config (e.g., `mlx_max_memory`, `VLLM_MAX_MEMORY`)
- [ ] Confirm OOM behavior: does the process get killed, crash gracefully, or hang?
- [ ] Test with the largest model on the lowest-spec target machine

## Port Allocation

- [ ] Check the existing port table in CLAUDE.md before choosing a port
- [ ] Verify the chosen port is not used by another service (`lsof -i :<port>`)
- [ ] Document the new port in the CLAUDE.md port table and Model Routing Rules
- [ ] If the backend exposes multiple endpoints (health, metrics, API), document all of them
- [ ] Update PAL MCP configuration to reference the correct port

## CLI Flag Stability

- [ ] Pin the backend to a specific version (Nix hash, pip version, or tagged release)
- [ ] List every CLI flag used in the LaunchAgent plist or service config
- [ ] Verify each flag exists in the pinned version's `--help` output
- [ ] Check the upstream changelog for recently deprecated or renamed flags
- [ ] Add a CI or rebuild-time check that validates critical flags still exist
- [ ] Document a plan for handling upstream breaking changes (flag renames, removed options)

## Version Pinning Strategy

- [ ] Record the exact version being integrated (commit SHA, release tag, or Nix derivation hash)
- [ ] Define the update cadence: who checks for updates, and how often
- [ ] Pin in a single location (flake input, overlay, or package definition) so updates are atomic
- [ ] Test the upgrade path: can you bump the version and rebuild without manual intervention?

## Rollback Plan

- [ ] Document the exact rollback command (`darwin-rebuild switch --rollback`, `git revert`, etc.)
- [ ] Verify rollback removes or stops the new backend service cleanly
- [ ] Confirm rollback restores the previous port allocation (no orphaned listeners)
- [ ] Test rollback on a clean system before merging
- [ ] Ensure rollback does not require manual cleanup of LaunchAgent plists or state files

## Environment Variables

- [ ] List every new environment variable the backend introduces
- [ ] Check for naming conflicts with existing variables (`env | grep -i <prefix>`)
- [ ] Follow the existing naming convention (e.g., `MLX_*`, `VLLM_*`)
- [ ] Document which variables are required vs. optional, with defaults
- [ ] Verify variables are set in the correct scope (LaunchAgent plist, shell profile, or Nix config)

## LaunchAgent / Service Management

- [ ] Define startup order: does this service depend on another (e.g., network, vllm-mlx)?
- [ ] Add a health check endpoint or command (e.g., `curl http://localhost:<port>/v1/models`)
- [ ] Set `KeepAlive` or restart policy so the service recovers from crashes
- [ ] Set `ThrottleInterval` to prevent restart loops from consuming resources
- [ ] Verify the service starts on boot and after `darwin-rebuild switch`
- [ ] Test crash recovery: kill the process and confirm it restarts within the expected interval
- [ ] Confirm logs are accessible (`log show --predicate` or a known log path)
