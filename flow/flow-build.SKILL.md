---
name: flow-build
description: >
  Phase B of the personal delivery pipeline — build a doubt-gated plan and ship it,
  hands-off. Runs TDD per task, then verification (with a debug loop), simplify,
  observe, security-audit, review, and PR. Requires a plan sealed by /flow-decide.
  Triggers include "flow-build", "build the plan", "run the build phase", "ship the
  plan", "/flow-build".
---

# Skill: Flow — Build (Phase B)

Hands-off. Runs to a PR without intervention unless a gate blocks.

## Precondition — refuse without the seal

Read `docs/plans/[feature].md`. Confirm it contains:

```
## Doubt Gate — PASSED
```

**If absent, stop immediately:**

```
❌ Plan is not doubt-gated.
   docs/plans/[feature].md has no "## Doubt Gate — PASSED" block.
   Run /flow-decide first.
```

Do not build it anyway. Do not offer to run `/doubt` inline and continue — the gate
exists so that an unreviewed plan cannot reach implementation, and honouring it only
when convenient is the same as not having it.

## Step 1 — Implement, task by task

For each task in the plan, invoke `/tdd`.

That skill splits each task into a Test Writer agent (RED) and an Implementer agent
(GREEN + REFACTOR), with a coordinator gate between them. Do not collapse the two —
the failing-test gate is the reason to use it.

**Where the pack is present, `/ponytail` applies to the implementation too — but it never
outranks this gate**, and the pack says so itself: *"Never a reason to skip gates: the rule
trades less code for more thinking, not for skipped tests."* TDD's RED gate wins every time.
If a "lazier" solution cannot be expressed as a failing test first, it is not the lazier
solution; it is an untested one.

Commit per task. Do not batch tasks into one commit: a per-task commit is what makes
`git bisect` useful later, and what lets a single bad task be reverted alone.

**If a task blocks twice, stop.** Report which task, what was tried, and what the
blocker is. Two failures on the same task means the plan was wrong about it — that
is a planning problem, and grinding a third attempt will not fix it.

## Step 2 — Verification (with the debug loop)

Invoke `/verification`.

This is the step that catches "it does not actually work" — not `/observe`. Run the
tests, the linter, the type-checker, and the feature itself.

```
PASS → continue to Step 3
FAIL → /systematic-debugging
       → root cause found
       → /tdd  (write a REGRESSION TEST that reproduces it, then fix)
       → re-run verification
```

The regression test is not optional. A fix without a test that would have caught the
bug leaves the bug free to come back.

**Bound the loop: two full cycles.** If verification still fails after two
debug-and-fix rounds, stop and report. Repeated failure at this point means the plan
or the approach is wrong, and neither is fixable from inside the build phase.

## Step 3 — Simplify

**Where the ponytail pack is present**, apply `/ponytail` to your own diff first — climb the
ladder against code you just wrote, which is where speculative abstraction is easiest to see
— then invoke `/ponytail-review` on the same diff. The review is the defined
over-engineering pass — one line per finding: location, what to cut, what
replaces it (reinvented standard library, unneeded dependency, speculative abstraction,
dead flexibility). Where the pack is absent (`decider`, `doubter`) it cannot run; that is
expected, and this step is a no-op there.

**Where `/simplify-code` resolves**, it also runs, and it runs **first** — it is the
broader pass (dead code, duplication, speculative abstraction), so let it work before the
ponytail pass looks specifically for over-engineering.

Availability, measured on this box **2026-09-28**:

- `/simplify-code` resolves on **`builder`** only — live at
  `~/.hermes/profiles/builder/skills/software-development/simplify-code`, and at the repo
  tree `~/.hermes/hermes-agent/skills/software-development/simplify-code`.
- On `codemax`, `architect`, `planner`, `decider` and `doubter` it sits under
  `skills/.archive/` — a deliberate prune, not an accident. Do not resurrect it unless the
  user asks; the ponytail pass is the intended substitute.
- **An earlier revision of this file claimed it "exists only on the `default` profile, and
  neither `codemax` nor any bot profile ships it". That was backwards** (it is live on
  `builder`) and contradicted this same paragraph. Corrected here.

So: on `architect` and `planner` the ponytail pass carries this step alone; on `builder`
both run, `/simplify-code` first; anywhere else, report the skip and why.

**Ledger.** Then run `/ponytail-debt` and record its counted output — each `ponytail:`
marker in the diff is one row:

```
grep -rnE '(#|//) ?ponytail:' .
```

Report `<N> markers, <M> with no trigger.` A clean ledger reports
`No ponytail: debt. Clean ledger.` — that is a legitimate outcome, not a failure.

Runs **before** `/observe`, deliberately. Instrumentation is intentionally verbose —
correlation IDs, structured fields, span attributes. Simplify the feature code first, then
add telemetry, so simplification cannot strip the telemetry you are about to add.

## Step 4 — Observe (conditional)

Invoke `/observe` **if the diff adds any of:**

- a new HTTP endpoint or route
- a background job, worker, or scheduled task
- an outbound call to an external service or third-party API

Otherwise skip, and say so in the report. A pure UI change or an internal refactor
does not need new telemetry, and adding it anyway trains you to ignore the dashboard.

Defines the on-call questions first, then picks the signal. Never log PII. Never use
unbounded values as metric labels.

## Step 5 — Security audit (conditional)

Invoke `/security-audit` **if the diff touches any of:**

- authentication, authorization, sessions, tokens, or passwords
- payments or billing
- personal or user data
- file upload or download
- external API calls
- admin-only functions
- raw SQL or dynamically constructed queries

Otherwise skip, and say so in the report.

Runs **after** `/observe` on purpose: instrumentation is the most common way PII
enters a codebase, so an audit that runs before the logging is added cannot see the
lines most likely to leak. It also runs after `/simplify`, so it audits the final
code rather than a version that is about to be rewritten.

## Step 6 — Review

Invoke `/code-review`.

Last quality gate before the PR. It sees the final diff — implemented, verified,
simplified, instrumented, audited.

Fix Critical findings before proceeding. Warnings are a judgement call; record the
call rather than silently passing over it.

**No ponytail pass here.** A second over-engineering lens at Step 6 was considered and is
**not adopted** — the pack's pass lives at Step 3, where the code is still being shaped.
`/code-review` at this step is unchanged.

## Step 7 — PR

Invoke `/github-pr-workflow` (Hermes core — the tapway `pr` skill is security-blocked
for editing AGENTS.md; the built-in `github-pr-workflow` is the unblocked first-party
alternative and is what this pipeline uses for the PR step).

Rebases onto the target branch, resolves conflicts, runs tests, updates docs, pushes,
opens the PR, and updates the checklist.

## Report

```
## Flow — Build: complete

Plan:      docs/plans/[feature].md ([N] tasks)
Implement: [N]/[N] tasks, [N] commits
Verify:    ✅ [N] tests passing | debug cycles: [N]
Simplify:  [what changed, or "no change"]
Observe:   [what was instrumented, or "skipped — no new endpoint/job/integration"]
Security:  [findings, or "skipped — no sensitive surface touched"]
Review:    [N] critical fixed, [N] warnings [accepted/fixed]
PR:        #[N] — [title]
Simplify:  /ponytail-review: [N] cuts  |  debt: [N] markers, [M] no-trigger
```

Every conditional step reports either what it did or why it was skipped. A silent
skip is indistinguishable from a step that never ran.

**`/ponytail-gain` is display-allowed, per-repo numbers are not.** Its own text: *"These
are benchmark medians, not this repo. NEVER print a per-repo savings number … The only
real per-repo figures come from `/ponytail-debt` (a counted ledger)."* So the gain card
may appear in the report only as a **labelled benchmark card**; it must never be turned
into "this build saved X lines/tokens". The unbuilt version was never written, so there is
no baseline to subtract from.

## Budget — measured, not guessed

A real 13-task build (logic core -> rendering -> evidence harness) consumed **150 tool calls** and hit the
agent turn budget *before* `/simplify-code` and `/code-review` could run. Two rules follow:

- **Raise the budget before a long build:** `hermes -p <bot> config set agent.max_turns 300` (the measured
  build needed more than 150; the setting is per-profile, so set it on the builder only).
- **If it still runs out, finish the remaining quality steps as a SECOND PASS** on the same plan — never
  skip them silently. Report which steps did not run. A stopped run that says what it did not do is worth
  far more than one that implies completeness.

## Red flags

- ❌ Building a plan with no `## Doubt Gate — PASSED` block
- ❌ Treating `/observe` as the step that finds bugs — that is `/verification`
- ❌ Fixing a verification failure without a regression test
- ❌ Running `/simplify` after `/observe` (strips telemetry)
- ❌ Running `/security-audit` before `/observe` (misses PII in new log lines)
- ❌ Batching several tasks into one commit
- ❌ Grinding a third attempt at a task that has blocked twice
- ❌ Letting the ponytail rule past a gate — it never outranks TDD's RED gate
- ❌ Printing a per-repo savings number from `/ponytail-gain` (benchmark medians only)
