# Checklist — `/pr` tail gaps

Work-package tracker for [docs/plans/pr-tail-gaps.md](../plans/pr-tail-gaps.md) (issue #2).
Legend: 🔴 not started · 🟡 in progress · 🟢 done

| # | Task | Owner | Status | Evidence to attach |
|---|---|---|---|---|
| T1 | gbrain pull after `/plan` + sync before `/pr`, both `CODEMAX_ENABLED=1` gated | — | 🔴 | one dry cycle with the flag unset; grep of both wrappers |
| T2 | `db-reviewer` skill + conditional call from `pr` | — | 🔴 | skill resolves; findings on a DB branch; clean skip on a docs branch |
| T3 | `/repo-wiki-writer`: adopt or record "not adopted" with the measurement | — | 🔴 | `has_wiki` + a real page fetch; one of the two paths written down |
| T4 | `/deep-research`: install or stop referencing it | — | 🔴 | grep shows no dangling reference |
| T5 | `/doubt` divergence documented in both wrappers | — | 🔴 | the one-line statement in each file |
| T6 | Flow pair synced to root/`default` + Claude copy refreshed | — | 🔴 | `flow_skill_status.py` no DRIFT; hashes; backup + undo printed |

## Already done (not a task)

| Change | When | Evidence |
|---|---|---|
| `flow-build` Step 7 → tapway `/pr` instead of `/github-pr-workflow` | 2026-11-24 | codemax `flow-build` hash `cf7079c7`, version `2026-11-24.1` |

## Definition of done for the plan

- [ ] `python3 ~/.hermes/scripts/flow_skill_status.py` prints no `⚠ DRIFT`
- [ ] `pr` runs repo-docs, and has a db-reviewer step whenever the diff touches DB code
- [ ] No skill is described as "mandatory" anywhere it cannot actually run
- [ ] A run with `CODEMAX_ENABLED` unset is silent about gbrain and still completes
- [ ] `docs/known-gaps.md` records every "not adopted" decision with its measurement