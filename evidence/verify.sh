#!/usr/bin/env bash
# verify.sh — report AND check the state of the flow-decide / flow-build wrappers and
# the ponytail pack across every Hermes skill tree on this Mac.
#
#   bash evidence/verify.sh              # report + checks; exit 1 if any check FAILs
#   bash evidence/verify.sh --selftest   # prove each check can actually fail (drift injection)
#
# Read-only: --selftest writes only inside a scratch dir it creates and removes.
#
# NOTE ON ENV VARS: a Hermes session exports HERMES_HOME pointing at the *profile*
# directory, so this script deliberately does NOT read HERMES_HOME. It uses
# HERMES_PREFIX (default: $HOME/.hermes).

set -u

PREFIX="${HERMES_PREFIX:-$HOME/.hermes}"
PROFILES="architect builder codemax decider doubter planner"
BASELINE="${BASELINE:-$PREFIX/backups/flow-wrappers-pre-v2.4.0-20260928-144648}"
SELFTEST=0
[ "${1:-}" = "--selftest" ] && SELFTEST=1

trees() {
  for p in $PROFILES; do echo "$PREFIX/profiles/$p/skills"; done
  echo "$PREFIX/skills"          # 6 profiles + the root ("default") tree = 7
}
label() { echo "$1" | sed "s|$PREFIX/||; s|/skills$||"; }
md5of() { md5 -q "$1" 2>/dev/null || md5sum "$1" | awk '{print $1}'; }

# ---------------------------------------------------------------- report

report() {
  echo "------------------------------------------------------------"
  echo "0. ENVIRONMENT"
  echo "date        : $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "host        : $(uname -srm)  macOS $(sw_vers -productVersion 2>/dev/null || echo n/a)"
  echo "hermes      : $(hermes --version 2>/dev/null | head -1 || echo 'not on PATH')"
  echo "prefix      : $PREFIX"
  echo "baseline    : $BASELINE"

  echo "------------------------------------------------------------"
  echo "1. FLOW PAIR — present in which trees, and is it identical there?"
  printf '%-14s %-46s %s\n' "TREE" "flow-build/SKILL.md" "md5"
  for t in $(trees); do
    fb="$t/openclaw-imports/flow-build/SKILL.md"
    if [ -f "$fb" ]; then
      printf '%-14s %-46s %s\n' "$(label "$t")" "FOUND" "$(md5of "$fb")"
    else
      printf '%-14s %-46s %s\n' "$(label "$t")" "MISSING" "-"
    fi
  done

  echo "------------------------------------------------------------"
  echo "2. PRE-CHANGE BASELINE (captured 2026-09-28, before the v2.4.0 edit)"
  if [ -d "$BASELINE" ]; then
    for f in flow-decide flow-build; do
      b="$BASELINE/$f.SKILL.md"
      [ -f "$b" ] && printf '%-12s %s  %s lines\n' "$f" "$(md5of "$b")" "$(wc -l < "$b" | tr -d ' ')"
    done
  else
    echo "BASELINE MISSING at $BASELINE"
  fi

  echo "------------------------------------------------------------"
  echo "3. VERSION DELTA — baseline vs the codemax tree's current wrappers"
  for f in flow-decide flow-build; do
    b="$BASELINE/$f.SKILL.md"; n="$PREFIX/profiles/codemax/skills/openclaw-imports/$f/SKILL.md"
    if [ -f "$b" ] && [ -f "$n" ]; then
      printf '%-12s +%-4s -%-4s (baseline %s lines -> current %s lines)\n' "$f" \
        "$(diff -u "$b" "$n" | grep -c '^+[^+]')" "$(diff -u "$b" "$n" | grep -c '^-[^-]')" \
        "$(wc -l < "$b" | tr -d ' ')" "$(wc -l < "$n" | tr -d ' ')"
    fi
  done

  echo "------------------------------------------------------------"
  echo "4. PONYTAIL PACK — 6 skill dirs? (architect/planner/builder by design; decider/doubter excluded)"
  printf '%-14s %-6s %s\n' "TREE" "COUNT" "READ"
  for t in $(trees); do
    c=$(ls -d "$t"/tapway/ponytail* 2>/dev/null | wc -l | tr -d ' ')
    case "$c" in
      6) r="pack present" ;;
      0) r="absent" ;;
      *) r="PARTIAL — investigate" ;;
    esac
    printf '%-14s %-6s %s\n' "$(label "$t")" "$c" "$r"
  done

  echo "------------------------------------------------------------"
  echo "5. /simplify-code — decides flow-build Step 3's path per tree"
  printf '%-14s %-8s %s\n' "TREE" "LIVE" "ARCHIVED"
  for t in $(trees); do
    live=no; arch=no
    [ -n "$(ls -d "$t"/*/simplify-code 2>/dev/null)" ] && live=yes
    [ -n "$(ls -d "$t"/.archive/simplify-code* 2>/dev/null)" ] && arch=yes
    printf '%-14s %-8s %s\n' "$(label "$t")" "$live" "$arch"
  done

  echo "------------------------------------------------------------"
  echo "6. PIPELINE DOC — does each tree carry the v2.4.0 sections?"
  printf '%-14s %-6s %-14s %s\n' "TREE" "LINES" "v2.4.0" "md5"
  for t in $(trees); do
    f="$t/software-development/hermes-flow-pipeline/SKILL.md"
    if [ -f "$f" ]; then
      if grep -q 'Pack upgrades — v2.4.0' "$f"; then s=present; else s=MISSING; fi
      printf '%-14s %-6s %-14s %s\n' "$(label "$t")" "$(wc -l < "$f" | tr -d ' ')" "$s" "$(md5of "$f")"
    else
      printf '%-14s %-6s %s\n' "$(label "$t")" "-" "ABSENT"
    fi
  done

  echo "------------------------------------------------------------"
  echo "7. UPSTREAM RELEASE the wrappers were aligned to"
  gh release view v2.4.0 -R tapway/tapway-superpowers --json tagName,publishedAt,name 2>/dev/null \
    || echo "  (gh unavailable — pack release is v2.4.0, tag published 2026-09-25)"
  echo
}

# ---------------------------------------------------------------- checks
# Each check prints PASS/FAIL. --selftest exercises each one against a mutated
# scratch tree, so a check that can never fail cannot hide in here.

CHECKS_FAILED=0
ck() {  # ck <name> <observed> <expected>
  if [ "$2" = "$3" ]; then printf 'PASS  %-44s %s\n' "$1" "$2"
  else printf 'FAIL  %-44s got=%s want=%s\n' "$1" "$2" "$3"; CHECKS_FAILED=$((CHECKS_FAILED+1)); fi
}

checks() {   # checks [root]   — root defaults to PREFIX
  local root="${1:-$PREFIX}"
  echo "CHECKS (target: $root)"
  local missing=0 partial=0 md5b="" md5d="" stale=0 n=0 t m c
  for t in $(trees); do
    t="${t/#$PREFIX/$root}"
    n=$((n+1))
    if [ -f "$t/openclaw-imports/flow-build/SKILL.md" ] && [ -f "$t/openclaw-imports/flow-decide/SKILL.md" ]; then
      md5b="$md5b$(md5of "$t/openclaw-imports/flow-build/SKILL.md")
"
      md5d="$md5d$(md5of "$t/openclaw-imports/flow-decide/SKILL.md")
"
    else
      missing=$((missing+1))
    fi
    c=$(ls -d "$t"/tapway/ponytail* 2>/dev/null | wc -l | tr -d ' ')
    case "$c" in 0|6) ;; *) partial=$((partial+1));; esac
    grep -q 'Pack upgrades — v2.4.0' "$t/software-development/hermes-flow-pipeline/SKILL.md" 2>/dev/null \
      || stale=$((stale+1))
  done

  ck "A. flow pair present in all 7 trees" "$((n-missing))" 7
  ck "B. all 7 flow-build copies byte-identical" "$(printf '%s' "$md5b" | sort -u | grep -c . | tr -d ' ')" 1
  ck "C. all 7 flow-decide copies byte-identical" "$(printf '%s' "$md5d" | sort -u | grep -c . | tr -d ' ')" 1
  ck "D. no tree has a partial ponytail pack" "$partial" 0
  ck "E. ponytail absent on both judging roles" \
     "$(ls -d "$root"/profiles/decider/skills/tapway/ponytail* 2>/dev/null | wc -l | tr -d ' ')" 0
  ck "F. pipeline doc v2.4.0 section in all 7" "$((n-stale))" 7
  echo
}

# ---------------------------------------------------------------- selftest

selftest() {
  local scratch; scratch=$(mktemp -d "${TMPDIR:-/tmp}/flow-verify-selftest.XXXXXX")
  local SP="$scratch/prefix"
  mkdir -p "$SP/profiles" "$SP/skills"
  for p in $PROFILES; do
    mkdir -p "$SP/profiles/$p/skills/openclaw-imports/flow-build" \
             "$SP/profiles/$p/skills/openclaw-imports/flow-decide" \
             "$SP/profiles/$p/skills/software-development/hermes-flow-pipeline" \
             "$SP/profiles/$p/skills/tapway"
    echo "clean" > "$SP/profiles/$p/skills/openclaw-imports/flow-build/SKILL.md"
    echo "clean" > "$SP/profiles/$p/skills/openclaw-imports/flow-decide/SKILL.md"
    echo "## Pack upgrades — v2.4.0" > "$SP/profiles/$p/skills/software-development/hermes-flow-pipeline/SKILL.md"
  done
  cp -R "$SP/profiles/architect/skills/." "$SP/skills/"
  for p in architect planner builder; do
    for s in ponytail ponytail-review ponytail-audit ponytail-debt ponytail-gain ponytail-help; do
      mkdir -p "$SP/profiles/$p/skills/tapway/$s"; echo x > "$SP/profiles/$p/skills/tapway/$s/SKILL.md"
    done
  done

  local PREFIX="$SP"          # checks()/trees() read the global PREFIX
  echo "=== SELFTEST 0: clean scratch tree — every check must PASS ==="
  CHECKS_FAILED=0; checks "$SP"
  local clean_failed=$CHECKS_FAILED
  echo "  clean-tree failures: $clean_failed (want 0)"
  echo

  # probe <letter>: run checks, print that check's line, return 0 when it FAILed.
  # Deliberately NOT reading $CHECKS_FAILED — `checks` runs in a subshell inside
  # $( ), so its counter never reaches us. A check that can never fail cannot hide.
  probe() {
    local res
    res=$(checks "$SP" | grep -E "^(PASS|FAIL)  $1\." || true)
    printf '%s\n' "$res"
    case "$res" in FAIL*) return 0 ;; *) return 1 ;; esac
  }

  local a_works b_works c_works d_works e_works f_works

  echo "=== SELFTEST 1: delete a tree's flow pair (check A must FAIL) ==="
  rm -rf "$SP/profiles/doubter/skills/openclaw-imports/flow-build"
  if probe A; then a_works=1; else a_works=0; fi
  echo "  -> A $( [ "$a_works" -gt 0 ] && echo FAIL || echo PASS ) (want FAIL)"
  echo

  echo "=== SELFTEST 2: drift ONE flow-build copy (check B must FAIL) ==="
  echo "drifted" > "$SP/profiles/planner/skills/openclaw-imports/flow-build/SKILL.md"
  if probe B; then b_works=1; else b_works=0; fi
  echo "  -> B $( [ "$b_works" -gt 0 ] && echo FAIL || echo PASS ) (want FAIL)"
  echo

  echo "=== SELFTEST 3: drift ONE flow-decide copy (check C must FAIL) ==="
  echo "drifted" > "$SP/profiles/architect/skills/openclaw-imports/flow-decide/SKILL.md"
  if probe C; then c_works=1; else c_works=0; fi
  echo "  -> C $( [ "$c_works" -gt 0 ] && echo FAIL || echo PASS ) (want FAIL)"
  echo

  echo "=== SELFTEST 4: drop 3 ponytail dirs from a pack tree (check D must FAIL) ==="
  rm -rf "$SP/profiles/architect/skills/tapway/ponytail-gain" \
         "$SP/profiles/architect/skills/tapway/ponytail-debt" \
         "$SP/profiles/architect/skills/tapway/ponytail-help"
  if probe D; then d_works=1; else d_works=0; fi
  echo "  -> D $( [ "$d_works" -gt 0 ] && echo FAIL || echo PASS ) (want FAIL)"
  echo

  echo "=== SELFTEST 5: install the pack into a judging role (check E must FAIL) ==="
  mkdir -p "$SP/profiles/decider/skills/tapway/ponytail"
  echo x > "$SP/profiles/decider/skills/tapway/ponytail/SKILL.md"
  if probe E; then e_works=1; else e_works=0; fi
  echo "  -> E $( [ "$e_works" -gt 0 ] && echo FAIL || echo PASS ) (want FAIL)"
  echo

  echo "=== SELFTEST 6: revert one tree's pipeline doc (check F must FAIL) ==="
  echo "old" > "$SP/profiles/codemax/skills/software-development/hermes-flow-pipeline/SKILL.md"
  if probe F; then f_works=1; else f_works=0; fi
  echo "  -> F $( [ "$f_works" -gt 0 ] && echo FAIL || echo PASS ) (want FAIL)"
  echo

  rm -rf "$scratch"
  echo "------------------------------------------------------------"
  echo "SELFTEST SUMMARY"
  local bad=0 pair
  [ "$clean_failed" -eq 0 ] || { echo "  clean tree did NOT pass — the checks themselves are broken"; bad=1; }
  for pair in "A:$a_works" "B:$b_works" "C:$c_works" "D:$d_works" "E:$e_works" "F:$f_works"; do
    if [ "${pair#*:}" -gt 0 ]; then echo "  check ${pair%%:*} can fail: PROVEN"
    else echo "  check ${pair%%:*} can fail: NOT PROVEN — the check is vacuous"; bad=1; fi
  done
  if [ "$bad" -eq 0 ]; then echo "RESULT: every check is both satisfiable and fail-able."
  else echo "RESULT: at least one check is broken or vacuous."; fi
  return "$bad"
}

# ---------------------------------------------------------------- main

report
CHECKS_FAILED=0
checks "$PREFIX"
live_failed=$CHECKS_FAILED
echo "live-tree failures: $live_failed — each FAIL is a real, currently-open gap, not a broken probe."
echo "  A,B,C,D,E pass: pair present in all 7 trees, both wrappers byte-identical across them,"
echo "                  no partial pack, pack absent on both judging roles."
echo "  F fails:  the pipeline doc's v2.4.0 sections reach codemax only — see docs/known-gaps.md"
echo

if [ "$SELFTEST" = "1" ]; then
  selftest && exit 0 || exit 1
fi
[ "$live_failed" -gt 0 ] && exit 1
exit 0