---
name: flow-decide
description: >
  Phase A of the personal delivery pipeline — decide what to build and prove the
  decision survives scrutiny before any code is written. Runs interview →
  brainstorming → plan → doubt, and stops at a hard gate: no unresolved Actionable
  findings. Hands off to /flow-build. Triggers include "flow-decide", "start a new
  feature", "let's plan this properly", "run the decide phase", "/flow-decide".
---

# Skill: Flow — Decide (Phase A)

Interactive. You are in the loop for all of it. Ends at a gate, not at a PR.

The output is a plan that has survived adversarial review. `/flow-build` refuses to
run without it.

## Why this order

Each step consumes the previous step's output. Skipping one means the next runs on
an assumption instead of a decision.

| Step | Consumes | Produces |
|---|---|---|
| `interview` | the fuzzy request | Confirmed Intent |
| `brainstorming` | Confirmed Intent | chosen approach + rejected alternatives |
| `writing-plans` | chosen approach | task breakdown + success criteria |
| `doubt` | the plan | Actionable findings, fixed |

> Skill names are exact. The tapway README writes them as `/plan`, `/review`,
> `/verify` — those short aliases **do not resolve**. In Hermes each has its own
> name (`/writing-plans`, `/code-review`, `/verification`); always invoke the
> specific skill named below.

## Step 1 — Interview

Invoke `/interview`.

Skip **only** if the request already states: the outcome, who it is for, why now,
what success looks like, and what is out of scope. If any of those five is missing,
do not skip — that is exactly the gap this step exists to close.

Stop when you can predict the user's answer to the next three questions. Output a
**Confirmed Intent** statement and get explicit confirmation before moving on.

## Step 2 — Brainstorm

Invoke `/brainstorming`.

Skip only if there is genuinely one viable approach — and say why in one line, so
the skip is a recorded decision rather than an omission.

Commits to `docs/brainstorming/[topic].md`. The rejected alternatives matter as much
as the chosen one: they are the answer to "why did we build it this way" six months
from now.

**Where the ponytail pack is present, invoke `/ponytail` before settling the option set.**
Every option set must then contain a *do nothing* / *the smallest thing* option, because
rung 1 of its ladder is *does this need to exist at all?* A brainstorm with no YAGNI option
has not considered the first rung — name it among the rejected alternatives and say why it
lost.

Pack present on: `architect`, `planner`, `builder`, `codemax`, the root tree. **Absent
on `decider` and `doubter`** — the two judging roles, deliberately kept free of it so the
reviewer is not nudged toward "cut it". Where the pack is absent, skip this paragraph.

## Step 3 — Plan

Invoke `/writing-plans`.

Never skip for anything touching 3+ files. Produces:
- `docs/plans/[feature].md` — file map, task breakdown, success criteria per task
- `docs/checklists/[feature]-checklist.md` — work packages, for multi-task features

Every task needs a **verifiable** success criterion. "Works correctly" is not one.
If a task cannot be stated as a checkable condition, it is not yet planned — go back.

**Where the pack is present, apply `/ponytail` to the task list**: cut tasks the way you
cut code — the fewest tasks that satisfy the criteria, and the laziest design that works. A task that exists "for later"
is the planning form of scaffolding — rung 1 applies. Being lazy here shortens the
solution, never the reading: the *verifiable criterion* rule above still binds every
task that survives.

## Ponytail placement — the whole map, so it is not re-litigated

`/ponytail-audit` and `/ponytail-help` are **not** pipeline steps; they are on-demand.

| Skill | Where it belongs | Why |
|---|---|---|
| `/ponytail` | Step 2 (options) and Step 3 (task cut) here; Step 1 and Step 3 in `/flow-build` | the core rule — a reflex at decide time, not only at code time |
| `/ponytail-review` | `/flow-build` Step 3 simplify | the defined over-engineering pass on your own diff |
| `/ponytail-debt` | `/flow-build` Step 3, counted ledger | the only per-repo figure the pack authorises |
| `/ponytail-gain` | `/flow-build` Step 7 report, as a **labelled benchmark card** | its own text forbids a per-repo savings number |
| `/ponytail-audit` | **nowhere** — on-demand / scheduled hygiene | whole-repo scope, not diff scope; it would blur Step 3 |
| `/ponytail-help` | operator reference card | one-shot display, not a mode |

Installed on `architect`, `planner`, `builder`, `codemax`, the root tree. **Deliberately
absent on `decider` and `doubter`** — the two judging roles stay free of it so a reviewer
is never nudged toward "just cut it".

## Step 4 — Doubt (the gate)

Invoke `/doubt` against the plan.

Give the reviewer the plan and its contract. Never give it your reasoning — the
whole point is a fresh context that cannot be led toward your conclusion.

Classify every finding:

| Class | Action |
|---|---|
| **Actionable** | Fix the plan. Re-run doubt. |
| **Trade-off** | Document in the plan, proceed. |
| **Contract misread** | Note, discard. |
| **Noise** | Discard. |

Loop until no Actionable findings remain. **Maximum 3 cycles.**

### The gate

```
PASS  → zero unresolved Actionable findings
STOP  → 3 cycles elapsed with Actionable findings still open
```

On STOP: do not proceed, do not start building. Report what is still open and hand
the decision back. An unresolved Actionable finding at the plan stage is the
cheapest bug you will ever fix — spending another interview cycle beats discovering
it in code.

## Step 5 — Seal the handoff

Append to the bottom of `docs/plans/[feature].md`, verbatim:

```markdown
## Doubt Gate — PASSED

- Cycles run: [N]
- Actionable findings fixed: [M]
- Accepted trade-offs: [list, or "none"]
- Sealed: [YYYY-MM-DD]
```

Commit the plan, the checklist, and the brainstorming output together.

This block is the handoff contract. `/flow-build` looks for `## Doubt Gate — PASSED`
and refuses to run without it — so an unreviewed plan cannot reach implementation
by accident.

## Report

```
## Flow — Decide: complete

Feature:   [name]
Intent:    [one line from Confirmed Intent]
Approach:  [chosen] (rejected: [alternatives])
Plan:      docs/plans/[feature].md — [N] tasks
Doubt:     [N] cycles, [M] actionable findings fixed
Trade-offs accepted: [list or none]

Gate: PASSED ✅

Next: /flow-build
```

## Verification budget — bound the self-checks

"Verify every number you change", with no stop condition, becomes an unbounded research spiral: one run
spent 2 hours generating 7 scratch scripts, re-opening settled questions while its deliverable sat
untouched. Bound it:

- verify only what a finding requires, then stop;
- if a sweep suggests a pin should change, record it as an **OPEN QUESTION for the doubt gate** instead of
  re-pinning — the gate owns adversarial re-examination, and a planner that re-verifies without limit is a
  cost centre, not a safeguard.

## Red flags

- ❌ Starting `/plan` before Confirmed Intent is stated and agreed
- ❌ Running `/doubt` on your reasoning instead of on the artifact
- ❌ Reclassifying an Actionable finding as Trade-off to get through the gate
- ❌ Proceeding to `/flow-build` after a STOP
- ❌ Sealing the plan without committing it
- ❌ A brainstorm with no *do nothing* / *smallest thing* option where the pack is present
