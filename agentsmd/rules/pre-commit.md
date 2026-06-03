# Pre-Commit Architecture

Single canonical home per artifact. No per-repo duplication of hook
definitions or shared lint configs.

| Artifact | Canonical home | How consumers pull it |
| --- | --- | --- |
| Pre-commit hook definitions (Nix consumers) | [`dryvist/nix-devenv`](https://github.com/dryvist/nix-devenv) — `lib/pre-commit-hooks.nix` + `flake-modules/profiles/<name>.nix` | `imports = [ inputs.nix-devenv.flakeModules.<profile> ]` in the consumer's `flake.nix` |
| Pre-commit hook definitions (non-Nix consumers) | [`dryvist/.github`](https://github.com/dryvist/.github) `precommit/templates/<profile>.yaml` | Copy at scaffold; Renovate keeps `rev:` pins fresh |
| Shared lint configs (`.markdownlint-cli2.yaml`, `.tflint.hcl`, `.ansible-lint`, `.yamllint.yml`) | `dryvist/.github` — `.markdownlint-cli2.yaml` at root for backward compat; the rest in `precommit/configs/` | Nix path: `nix-devenv.lib.fetch-shared-configs` materializes nix-store paths; non-Nix path: copy at scaffold |
| `zizmor.yml` workflow-security policy | `dryvist/.github` at the root | Same as above — passed as `--config` by the base profile's zizmor hook |

## Profiles

`nix-devenv` exports six profile names. Pick one per consumer repo.

| Profile | Adds on top of base hygiene | Inventory match |
| --- | --- | --- |
| `base` | Nothing — exposes the base wiring (deadnix, statix, check-yaml/toml/json, check-merge-conflict, check-added-large-files=500k, end-of-file-fixer, trim-trailing-whitespace, detect-private-keys, markdownlint-cli2, zizmor, treefmt) | Generic repos |
| `nix` | Alias for `base` (deadnix and statix file-glob to `.nix` automatically) | nix-* repos |
| `markdown` | Alias for `base` (markdownlint-cli2 file-globs to `.md` automatically) | Markdown-heavy repos |
| `terraform` | `terraform-format`, `terraform-validate`, `tflint` | `terraform-*`, `tofu-*` |
| `ansible` | `ansible-lint`, `yamllint` | `ansible-*` |
| `python` | `ruff`, `ruff-format`, `mypy` | python-template, mlx-benchmarks, etc. |

The base wiring already covers Nix lints (`deadnix`, `statix`) and
markdown (`markdownlint-cli2`); `git-hooks.nix`'s file-glob filters
make those hooks inert on repos that don't have the matching file
types. So `base`, `nix`, and `markdown` are deliberately identical
modules — the name signals intent to the reader, not behavior.

## Consumer pattern (Nix path, preferred)

```nix
# flake.nix in a consumer repo
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-devenv = {
      url = "github:dryvist/nix-devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, nix-devenv, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [ nix-devenv.flakeModules.terraform ];

      perSystem =
        { system, ... }:
        {
          devShells.default = nix-devenv.devShells.${system}.terraform;
        };
    };
}
```

Scaffold a new repo with this layout via
`nix flake init -t github:JacobPEvans/nix-devenv#with-hooks`.

## Consumer pattern (non-Nix path)

```bash
# Pick the matching profile template
gh api repos/dryvist/.github/contents/precommit/templates/terraform.yaml \
  -H "Accept: application/vnd.github.raw" > .pre-commit-config.yaml

# Materialize the configs the hooks need
gh api repos/dryvist/.github/contents/precommit/configs/tflint.hcl \
  -H "Accept: application/vnd.github.raw" > .tflint.hcl
gh api repos/dryvist/.github/contents/.markdownlint-cli2.yaml \
  -H "Accept: application/vnd.github.raw" > .markdownlint-cli2.yaml
gh api repos/dryvist/.github/contents/zizmor.yml \
  -H "Accept: application/vnd.github.raw" > zizmor.yml

pre-commit install
```

## Rules for AI agents

- Do NOT add hook definitions to consumer-repo `.pre-commit-config.yaml`
  files. If the canonical profile doesn't cover something, add it to
  `nix-devenv`'s base profile (in `lib/pre-commit-hooks.nix`) or the
  matching profile (in `flake-modules/profiles/<name>.nix`), then pull
  it through everywhere on the next `nix flake update`.
- Do NOT duplicate shared lint config files (`.markdownlint`,
  `.tflint.hcl`, `.ansible-lint`, `.yamllint`) into a new repo. Pull
  them via the Nix path (`fetch-shared-configs`) or copy from
  `dryvist/.github` at scaffold (non-Nix path).
- When opening a PR that adopts the architecture in a new consumer
  repo, the diff is approximately: add `flake.nix` + `flake.lock`,
  modify `.envrc`, delete `.pre-commit-config.yaml`, delete the
  duplicated lint config files that the canonical now covers.
- Hook versions are pinned via `flake.lock` (Nix path) or `rev:`
  strings in the static template (non-Nix path). Do NOT pin versions
  per-repo unless overriding a specific consumer.
- See [`precommit/README.md` in `dryvist/.github`](https://github.com/dryvist/.github/blob/main/precommit/README.md)
  for the architecture rationale, canonical-config choices, and the
  trade-offs behind why certain hooks (checkov, bandit, detect-secrets)
  stay opt-in per repo.

## Known limitations (as of 2026-05-31)

- `cachix/git-hooks.nix`'s built-in `tflint` wrapper drops args beyond
  `$1`, so the `terraform` profile's `--config <sharedConfigs.tflint>`
  plumbing doesn't reach tflint. Consumers either keep a synced copy of
  the canonical `.tflint.hcl` in the repo (tflint's local-config
  discovery still finds it) or override `tflint.args` to `lib.mkForce
  [ ]`. An upstream fix to the wrapper would let
  `fetch-shared-configs` drive tflint config directly.
- `terraform-validate` hooks need network access to `tofu init`
  external modules. `nix flake check` runs hooks in a sandboxed
  environment without network. Repos with external module references
  override `terraform-validate.enable = lib.mkForce false` for the
  flake-check path and rely on CI's OIDC-authenticated
  `terragrunt validate` to cover the check.
- `gitleaks` is not in `cachix/git-hooks.nix`'s built-in hook set yet.
  Consumers that want it wire it as a custom hook locally; a follow-up
  adds it to the base profile.
