---
issue: 2
status: planned
---

# Close the `/pr` tail gaps in the Hermes flow

## Why

The team's published pipeline (Jing Yu, Slack `C056V1ZAA82`, 2026-11-24) is:

`/interview → /brainstorming → /plan → [implement] → /simplify → /review → /pr`
with `/doubt` on demand, and `/pr` itself a mini-pipeline (rebase → tests → db-reviewer →
**repo-docs** → **repo-wiki-writer** → codemax sync → push/PR).

Measured 2026-11-24 against the installed skills, the Hermes implementation matches through `/plan`
and `/tdd`, and diverges at the tail:

| Spec step | Status before this plan | Evidence |
|---|---|---|
| interview → Confirmed Intent | matches | `flow-decide` steps 1–2 |
| brainstorming + `Grounding:` | matches (detail in Task 5) | local `brainstorming` copy |
| `/plan` + checklist + GH issue + `issue: N` | matches | `flow-decide` step 7 |
| gbrain pull after `/plan` | **missing** | no `gbrain` reference in `flow-decide` |
| `/tdd` RED/GREEN two-agent + E2E gate | matches | `tapway/tdd` step 3 |
| `/pr` rebase, tests, repo-docs | matches **once `/pr` is called** | `tapway/pr` line 104: repo-docs mandatory |
| `/pr` db-reviewer checks | **missing** | `grep db-reviewer` in `tapway/pr` → 0 |
| `/pr` repo-wiki-writer | **missing** | skill not installed in the Hermes tree |
| `codemax sync run` before PR | **missing** | no reference in `flow-build` or `pr` |
| `/deep-research` | **missing** | skill not installed |

**Already done, outside this plan:** `flow-build` Step 7 now calls tapway `/pr` instead of
`/github-pr-workflow`. That was one line and it reconnected the repo-docs obligation; it is not
repeated as a task here.

## File map

| File | Change |
|---|---|
| `~/.hermes/profiles/codemax/skills/openclaw-imports/flow-decide/SKILL.md` | gbrain pull after `/plan`; one line on the `/doubt` divergence |
| `~/.hermes/profiles/codemax/skills/openclaw-imports/flow-build/SKILL.md` | gbrain sync before `/pr`; one line on the `/doubt` divergence |
| `~/.hermes/profiles/codemax/skills/tapway/pr/SKILL.md` | insert the db-reviewer step + gbrain sync step, both conditional |
| `~/.hermes/profiles/codemax/skills/tapway/db-reviewer/SKILL.md` | **new** (if Task 2 resolves to "build") |
| `~/.hermes/profiles/codemax/skills/tapway/repo-wiki-writer/SKILL.md` | **new** only if Task 3 resolves to "adopt" |
| `~/.hermes/profiles/codemax/skills/software-development/hermes-flow-pipeline/SKILL.md` | record the outcome of every task |
| `docs/known-gaps.md` (this repo) | pointer line; "not adopted" entries with reasons |

## Tasks

### T1 — Wire gbrain context into the flow

`codemax-gbrain` exists and documents the pull/sync bridge, but nothing calls it.

- In `flow-decide`, after the plan exists and carries `issue: N`: if `CODEMAX_ENABLED=1`, pull the
  traced requirement / blueprint / ADR for that issue from gbrain and append it to the plan's
  context section.
- In `flow-build`, before Step 7 pushes: if `CODEMAX_ENABLED=1`, run the docs sync so living docs
  reach the shared brain.

**Success criteria**

1. Both files contain the literal `CODEMAX_ENABLED=1` gate and the exact command each step runs.
2. With `CODEMAX_ENABLED` unset, a full `flow-decide` + `flow-build` run performs **zero** gbrain
   calls and reports nothing about gbrain — verified by running one dry cycle, not by reading.
3. Each step's report line says either "gbrain: pulled N artifacts for issue X" or
   "gbrain: skipped (CODEMAX_ENABLED unset)". Never silent, never implied.

### T2 — Give `/pr` a db-reviewer step

`tapway/pr` has no equivalent of upstream step (c). Build a `db-reviewer` skill and call it
conditionally from `pr`, mirroring how `observe` is called before a PR.

Checks it must implement, in this repo family's terms: N+1 query patterns on SQLAlchemy
relationships, missing indexes on new FK/filter columns, migration safety for the **boot-time
idempotent** scheme (`migrations.STEPS` runs on every start, so a non-idempotent step is fatal), and
`EXPLAIN ANALYZE` on the hot query when a Postgres DSN is available.

**Success criteria**

1. `hermes -p codemax skills list | grep db-reviewer` resolves.
2. Given a branch touching `models.py` or `migrations.py`, the skill reports at least one finding per
   category it can evaluate, and explicitly lists categories it could not evaluate and why.
3. Given a docs-only branch, it prints `db-reviewer: skipped — no DB code in diff` and does not
   fabricate findings.
4. The skill states that this fork has **no down-migrations** and treats that as a standing risk
   rather than a gap it can fix.

### T3 — Decide `/repo-wiki-writer`

Upstream step (e) is mandatory on every PR; the skill ships only in the Claude tree.

- First measure: does any Tapway repo in use here have a GitHub Wiki with content
  (`gh api repos/<owner>/<repo>/contents --path /` is not enough — check the wiki clone or the
  `has_wiki` flag plus a real page fetch)?
- If yes → port the skill and wire it into `pr` step (e).
- If no → record "not adopted" in `docs/known-gaps.md` with the measurement that justified it, and
  make `pr` print `wiki: not updated (repo has no wiki content)`.

**Success criteria:** exactly one of the two paths is taken, and `pr`'s report line matches reality
in both cases. The word "mandatory" is not used about a step that cannot run.

### T4 — Resolve `/deep-research`

The published pipeline says "run `/deep-research` first if the domain is unfamiliar";
the skill is not installed. Either install it or stop referencing it.

**Success criteria:** `flow-decide` and the pipeline docs either name a skill that resolves, or name
none. No dangling reference survives.

### T5 — Document the `/doubt` divergence

The team default is "on demand, before anything hard to undo"; the flow makes it a hard seal that
`flow-build` refuses without. That is a defensible choice and currently undocumented.

**Success criteria:** `flow-decide` and `flow-build` each carry one line stating that the gate is
**stricter than the team default** and naming `/autoship` as the ungated alternative — so a reader
who saw the Slack summary cannot conclude both paths are equally gated.

### T6 — Stop the three-copy drift

`flow_skill_status.py` reports DRIFT for both wrappers (codemax vs root). A third copy lives in
`~/.claude/skills/` and is older still.

- Propagate the codemax text to root/`default` **deliberately** (root serves a different profile).
- Refresh the Claude copy from codemax, with a backup directory and the before/after hashes printed.

**Success criteria:** `flow_skill_status.py` prints no DRIFT line; the three copies are compared by
hash and the values are reported; a backup path and an undo command are printed for every file
overwritten.

## Verification (whole plan)

```bash
# wrappers agree
python3 ~/.hermes/scripts/flow_skill_status.py            # expect no DRIFT
# the PR tail now has every step that exists here
grep -c "repo-docs" ~/.hermes/profiles/codemax/skills/tapway/pr/SKILL.md   # >= 1
grep -c "db-reviewer" ~/.hermes/profiles/codemax/skills/tapway/pr/SKILL.md # >= 1
grep -c "CODEMAX_ENABLED" ~/.hermes/profiles/codemax/skills/openclaw-imports/flow-*/SKILL.md
# nothing claims a step it cannot run
grep -rn "repo-wiki-writer" ~/.hermes/profiles/codemax/skills/ | grep -v known-gaps
```

## Out of scope

- Routing `flow-build` through `/autoship` — it is a deliberate alternative, not a gap.
- Changing `/tdd`, `/doubt`'s mechanism or its 3-cycle ceiling.
- Upgrading the tapway-superpowers pack (destructive installer; separate decision).
- Rebuilding the 5 bot profiles that used to host these roles.