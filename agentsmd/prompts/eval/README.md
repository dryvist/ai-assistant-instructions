# Promptstack eval suite

The promptstack eval suite decides whether a surface should adopt the shared
base prompt plus its variant, or keep its current prompt. This directory holds
the scaffold: the size gate that runs in CI today, and the spec for the fuller
harness that is still being built.

## What runs today

[`check-core-size.sh`](check-core-size.sh) is the live gate, wired into
[`.github/workflows/promptstack.yml`](../../../.github/workflows/promptstack.yml).
It asserts two budgets:

- The always-on rule core -- every top-level `agentsmd/rules/*.md` whose
  frontmatter has no `paths:` key -- sums to <= 4000 body chars.
- The autonomous base prompt's fenced text block is <= 4000 chars.

Run it locally the same way CI does:

```bash
bash agentsmd/prompts/eval/check-core-size.sh
```

## What the full suite evaluates

The suite scores `base + variant` against the surface's current prompt across
matched probes in four categories:

- **Reasoning** -- multi-step problems that need a plan before an answer.
- **Tool-call fidelity** -- does the model call the right tool with valid
  arguments, and skip a call when preconditions are not met.
- **Instruction-following** -- does it honor the ordered rules (ground truth,
  verify, reversibility gate, output shape).
- **Homelab-context Q&A** -- questions that need the homelab conventions the
  base prompt encodes.

Each probe declares an `expected_signal` the scorer checks for. See
[`probes.example.yml`](probes.example.yml) for the shape.

## Adoption rule

A surface adopts `base + variant` only when, on the matched probe set, it scores
**task success and tool-call validity >= the current prompt at <= the current
token count**. Equal quality at fewer tokens is an adoption; more tokens for the
same quality is not.

## Status

This README and `probes.example.yml` are a scaffold, not a live suite. The full
harness build -- runner, scorer, and the real probe set -- is tracked in
`mlx-benchmarks`. The only piece enforced in CI today is the size gate above.
