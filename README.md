# hermes-flow-pipeline

Documentation for my personal **plan-then-build pipeline** running on this Mac: an
interactive *decide* phase that seals a plan behind an adversarial gate, and a
hands-off *build* phase that ships that plan to a PR.

```
/flow-decide   interview → brainstorming → plan → doubt (gate) → SEAL
/flow-build    TDD → verification → simplify → observe → security-audit → review → PR
```

This repo is the **record** of how the pipeline is wired, what changed in the
v2.4.0 alignment of its two wrappers, and what is still open. It is documentation,
not a package — nothing here is meant to be installed from this repo.

## What this repo answers

| Question | Where |
|---|---|
| What are the two phases, step by step, and what gates them? | [`docs/pipeline.md`](docs/pipeline.md) |
| What changed in the flow wrappers for the v2.4.0 pack alignment, and how do I prove it? | [`docs/v2.4.0-update.md`](docs/v2.4.0-update.md) |
| What is still broken or unfinished? | [`docs/known-gaps.md`](docs/known-gaps.md) |
| Show me — run something | `bash evidence/verify.sh` |

## The v2.4.0 wrapper update, in one paragraph

On **2026-09-28**, the two wrappers (`flow-decide`, `flow-build`) were updated to
assimilate the **v2.4.0 ponytail skill pack** (6 skills; upstream release
published 2026-09-25). The change gives every ponytail skill a *named* place in the
pipeline — or a recorded decision that it has none — without letting the
"laziest-solution" rule outrank any existing gate. `flow-decide` grew from 140 to
185 lines (+35/−0) to put YAGNI into the option set and the task cut;
`flow-build` grew from 159 to 224 lines (+56/−4) to rewrite Step 3 around a real
procedure, add the counted debt ledger, record that a second over-engineering lens
was **not** adopted, and add a measured turn-budget rule.

Full detail, with the numbers and the way to re-measure them:
[`docs/v2.4.0-update.md`](docs/v2.4.0-update.md).

## Machine layout (measured, not assumed)

Seven skill trees carry the flow pair on this Mac — 6 profiles plus the root
("default") tree:

```
~/.hermes/skills/                                     <- root / default tree
~/.hermes/profiles/{architect,builder,codemax,decider,doubter,planner}/skills/
```

| Piece | Path (repo-relative inside a tree) |
|---|---|
| flow-decide wrapper | `openclaw-imports/flow-decide/SKILL.md` |
| flow-build wrapper | `openclaw-imports/flow-build/SKILL.md` |
| pipeline wiring doc | `software-development/hermes-flow-pipeline/SKILL.md` |
| the pack the wrappers call | `tapway/ponytail*` (6 skills) |

As of 2026-09-28 all **7 flow-build copies are byte-identical**
(`916c3088b84ab0deedb183448fd0f6f5`) — the wrapper text reached every tree.
The pipeline *wiring doc*, however, reached **codemax only**; the other 6 trees
still carry the older 100-line copy. That is check `E` in `verify.sh` and it is
recorded honestly in [`docs/known-gaps.md`](docs/known-gaps.md).

## Running it

The wrappers are not a CLI — they are skill instructions a Hermes agent follows
when the slash command is invoked:

```
/flow-decide        # interactive; ends at the gate, not at a PR
/flow-build         # hands-off; refuses to run on an unsealed plan
```

`flow-build` reads `docs/plans/[feature].md` and stops immediately unless it
contains the literal heading `## Doubt Gate — PASSED`. A plan author sealing its
own plan is invalid; the seal is written by a separate reviewer context.

## Verifying the claims in this repo

```bash
bash evidence/verify.sh              # report + checks; exit 1 if any check FAILs
bash evidence/verify.sh --selftest   # prove every check can actually fail
```

`verify.sh` is read-only against a live `~/.hermes` and prints what it measured:
the flow pair per tree with md5s, the pre-change baseline, the line delta, the
ponytail pack per tree, `/simplify-code` availability per tree, and the upstream
release it was aligned to.

The six checks are `A` flow pair present in all 7 trees · `B` all 7 flow-build
copies byte-identical · `C` all 7 flow-decide copies byte-identical · `D` no
partial pack · `E` pack absent on both judging roles · `F` pipeline doc's v2.4.0
sections present in all 7. On 2026-09-29 the live run returned **A–E pass / F
fails**, and `--selftest` proved all six checks can fail against a deliberately
mutated scratch tree — so `F` failing is a real gap, not a broken probe. Captured
output:
[`evidence/verify-output-20260929-0942.txt`](evidence/verify-output-20260929-0942.txt),
[`evidence/selftest-output.txt`](evidence/selftest-output.txt).

## What is versioned here, and what is not

- **Versioned:** this documentation, the evidence harness, the v2.4.0 diffs, and
  a snapshot of the current wrapper text under [`flow/`](flow/).
- **Not versioned, on purpose:** the live wrappers themselves. They live in
  `~/.hermes/**/skills/` as unversioned profile config, so a backup is what
  substitutes for a diff there. See the limitation recorded in
  [`docs/known-gaps.md`](docs/known-gaps.md).

## Attribution

The pipeline calls skills from the **tapway-superpowers** pack (public:
`github.com/tapway/tapway-superpowers`, MIT) and the **ponytail** pack carried by
its v2.4.0 release. The `flow-decide` / `flow-build` wrappers in [`flow/`](flow/)
are my own hand-maintained launchers — they are *not* part of that pack, and the
pack installer never touches them.