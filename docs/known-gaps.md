# Known gaps

Open items as of **2026-09-29**. Each one is measured, not estimated, and each
says what closing it would actually require.

---

## 1. The pipeline wiring doc reached codemax only

**What is true:** the v2.4.0 sections of the pipeline doc
(`software-development/hermes-flow-pipeline/SKILL.md` — the pack-upgrade record,
bot-team topology, room-runner runbook) exist on **codemax** (277 lines,
`d0a2c705ff3eb22910b61d1c3617bc2f`). The root tree and all five bot trees still
carry the older 100-line copy (`36440a4345b99f8af19f8482f98d323b`).

**Why it matters:** this is the skill that a `/flow-decide` or `/flow-build` run
loads *to know how to run itself*. A bot reading the stale copy sees wiring facts
that were corrected in September — including an earlier, **false** claim about
`/simplify-code` availability that the codemax copy explicitly corrects.

**Measured by:** `evidence/verify.sh` check `F` — currently **FAIL**
(`got=1 want=7`).

**What closing it requires:** propagate the codemax text to the other six trees
(backup first), then confirm with the same grep the harness runs. Note the six
copies are byte-identical to each other, so this is one text applied six times,
not six merges — but *verify* that before overwriting, because per-profile drift
in this tree is real and has been observed before.

---

## 2. The wrappers are unversioned profile config

**What is true:** `flow-decide` / `flow-build` live at
`~/.hermes/**/skills/openclaw-imports/flow-{decide,build}/SKILL.md` — unversioned
files in a Hermes profile tree, not in a git repository.

**Why it matters:** there is no commit history for them, so "what changed" can
only be answered against a **backup directory**. The v2.4.0 delta in this repo is
exactly that: baseline = a backup captured before the edit. It is verifiable, but
it is not a diff against a commit, and it is only as durable as the backup dir.

**Mitigation in place:** `evidence/verify.sh` prints `BASELINE MISSING` and aborts
the delta section if the backup is gone, so the claim degrades loudly rather than
silently. This repo also carries the diffs as files, so the record survives the
baseline being deleted — but the diffs then cannot be *regenerated*, only read.

**What closing it would require:** a git-backed skill tree, or a scheduled export
of the wrappers into a versioned repo. Both are distribution changes and were
deliberately kept out of scope for the v2.4.0 wrapper alignment.

---

## 3. `/simplify-code` is archived on six of the seven trees

**What is true:** live on `builder` only. Archived (`skills/.archive/`) on the
root tree, `architect`, `planner`, `codemax`, `decider`, `doubter`.

**Why it matters:** it is not a gap in the wrapper so much as a **documented
asymmetry**: `flow-build` Step 3 takes a different path per tree. On `builder`,
Step 3 runs `/simplify-code` *then* the ponytail review; on `architect`/`planner`
the ponytail pass carries the step alone; elsewhere the step is a reported skip.

**Measured by:** `evidence/verify.sh` section 5 (report only — not asserted as a
check, because the asymmetry is intentional rather than a defect).

**Status:** working as designed. `/simplify-code` was archived deliberately; the
ponytail pass is the intended substitute. Do not resurrect it unasked.

---

## 4. The pack's own installer is destructive — a re-install is not a safe default

**What is true:** the pack's `install.sh` does `rm -rf` on its destination before
copying. On this machine several profiles carry hand-written, incident-derived
lessons appended to upstream skills, which a plain reinstall would silently
delete.

**Why it matters:** "upgrade the pack" looks idempotent and is not. A merge-safe
classification script (dry-run by default, explicit `--apply`, explicit
`TARGETS`) is what is used instead here, and it refuses to overwrite local content
it cannot merge.

**Also recorded:** a silent skill-loss bug shipped in the pack's installed copies
— one skill repeated a frontmatter key, and Hermes drops a skill whose frontmatter
repeats a key, so the skill never resolved in *every* profile that installed that
release. Fixing the upstream repo does not retro-fix an installed copy: after any
pack upgrade you must prove the new skills **resolve**, not just that the
directory exists.

**Status:** external to this repo; recorded here because it is why the wrappers
document a specific upgrade path instead of "just reinstall".

---

## 5. Turn budget is still a per-profile manual setting

**What is true:** a measured 13-task build consumed **150 tool calls** and hit the
agent turn budget before its last two quality steps could run.

**Mitigation in place:** `flow-build` now says to raise the budget before a long
build (`hermes -p <bot> config set agent.max_turns 300`, set on the builder only)
and, if it still runs out, to **finish the remaining quality steps as a second
pass** — never to skip them silently.

**Why the gap remains:** the rule is a written instruction, not an enforced limit.
Nothing prevents a run from hitting the cap again; what changed is that a run
which does is now required to report the steps it did not run.

---

## Not gaps (considered and deliberately rejected)

| Rejected | Why |
|---|---|
| Wiring `ponytail-audit` as a pipeline gate | whole-repo scope vs diff scope — it would blur Step 3's purpose |
| A second over-engineering lens at `flow-build` Step 6 | considered, recorded as **not adopted** — the pass lives at Step 3, where the code is still being shaped |
| A per-repo savings number from `/ponytail-gain` | the unbuilt version was never written, so there is no baseline to subtract from; only the counted `ponytail:` ledger is a legitimate repo figure |
| Letting the ponytail rule override the TDD RED gate | the rule trades less code for more thinking, not for skipped tests |