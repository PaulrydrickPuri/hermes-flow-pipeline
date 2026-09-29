# The pipeline, step by step

Two slash commands, one contract between them: **`/flow-build` refuses to run
unless `/flow-decide` sealed the plan.**

A plan is sealed by a separate reviewer context appending the literal heading
`## Doubt Gate — PASSED` to `docs/plans/[feature].md`. The seal is a grep-able
string, and only the reviewer writes it — a plan author that seals its own plan
is invalid, so the author of the seal commit is always checked against the author
of the plan. Findings cycles append `## Doubt Gate — NOT SEALED (cycle-N …)`, and
the reviewer deliberately avoids the pass heading inside findings blocks so no
tool mistakes a findings block for a seal.

Cycle ceiling is 3. A STOP may legitimately *introduce* new residuals after
earlier findings closed clean; the final cycle's residuals cannot be forced
through. On exhaustion the run stops and hands back.

## Phase A — `/flow-decide` (interactive)

| Step | Consumes | Produces |
|---|---|---|
| `/interview` | the fuzzy request | Confirmed Intent, agreed with the user |
| `/brainstorming` | Confirmed Intent | 2–3 options in `docs/brainstorming/`, with rejected alternatives and why |
| `/writing-plans` | the chosen option | a plan in `docs/plans/` — **every task carries a verifiable success criterion** |
| `/doubt` | the plan as an artifact | findings, classified; Actionable findings block the gate |
| seal | a clean gate | `## Doubt Gate — PASSED`, committed |

Ends at a gate, never at a PR. "Works correctly" is not a success criterion; if a
task cannot be stated as a checkable condition it is not yet planned.

## Phase B — `/flow-build` (hands-off)

| Step | Runs | Notes |
|---|---|---|
| 0. Precondition | — | refuses without `## Doubt Gate — PASSED`; REFUSE, don't warn |
| 1. TDD | `/tdd` | RED → GREEN → REFACTOR with a coordinator gate between them; **the RED gate is never traded away** |
| 2. Verification | `/verification` | with a debug loop; `/systematic-debugging` on a real block |
| 3. Simplify | `/simplify-code` where it resolves, plus the over-engineering pass on your own diff | runs **before** Step 4 on purpose |
| 4. Observe | `/observe` (conditional) | instrumentation is verbose; simplify first so it can't strip the telemetry |
| 5. Security | `/security-audit` (conditional, after observe) | must run after observe — PII can appear in the log lines observe adds |
| 6. Review | `/code-review` | Critical findings fixed before proceeding; warnings are a recorded judgement call |
| 7. PR | `/github-pr-workflow` | `docs/`, commit per task, one PR |

Every conditional step reports **either what it did or why it was skipped**. A
silent skip is indistinguishable from a step that never ran.

## Why the order matters

Two orderings carry real cost if inverted:

- **Simplify before observe.** Instrumentation is intentionally verbose —
  correlation IDs, structured fields, span attributes. Simplifying afterwards
  strips the telemetry you just added.
- **Observe before security-audit.** New log lines are where PII leaks. An audit
  run before the logging change cannot see it.

## The four hard rules the wrappers enforce

1. **No build on an unsealed plan.** The gate exists to prevent exactly that.
2. **Commit per task, never batched.** A per-task commit is what makes `git
   bisect` useful later and what lets a single bad task be reverted alone.
3. **A "lazier" solution still needs a failing test first.** If it cannot be
   expressed as a failing test, it is not lazier — it is untested.
4. **Never grind a third attempt at a task that blocked twice.** Escalate.

## Skill-name facts worth not re-learning

- The pipeline calls skills by **bare name** (`/interview`, `/doubt`, `/tdd`), not
  by a `tapway-superpowers:` prefix.
- Step 7 uses `/github-pr-workflow`, **not** the pack's `pr` skill — that one is
  hard-blocked by the scanner in this environment, and `--force` does not
  override a dangerous verdict.
- `/simplify-code` is the real name (the older `/simplify` does not resolve).
- Duplicate skill names are fatal, not merely ambiguous: the loader refuses to
  guess and **neither** copy loads. Archive one.

## Where the wrappers live

| Tree | Path |
|---|---|
| root / default | `~/.hermes/skills/openclaw-imports/flow-{decide,build}/SKILL.md` |
| each profile | `~/.hermes/profiles/<name>/skills/openclaw-imports/flow-{decide,build}/SKILL.md` |

Seven trees, one text — see `evidence/verify.sh` check `B`.

## The pack upgrade rule

The wrappers are **not** part of the tapway-superpowers pack and the pack's
installer never touches them, so *"upgrade the pack" ≠ "upgrade the flow"*. The
pack supplies the skills the wrappers call; the wrappers are hand-maintained
launchers.

Also measured, and worth keeping: the pack installer does `rm -rf` on its
destination, so a plain reinstall silently deletes local, incident-derived
lessons appended to upstream skills. Per-profile drift is real — never assume one
profile's tree matches another's.