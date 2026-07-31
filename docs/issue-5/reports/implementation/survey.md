---
subject: issue-5
role: implementation
loop_state: open
---

# Current-state survey (issue-5)

## Scouting note

Skip condition met: no design decision is open beyond confirming an
already-published core convention. The comparable system is core's own
canon (`tokenmaxxxer-core`), read directly below; a web sweep would add
nothing a purpose-built handbook doesn't already state. Full scout not
run; this survey substitutes the "best comparable system" read.

## What exists in this repo

- `customer-support/hooks/tests/stub-check.sh` — a byte-identical vendored
  copy of `core/hooks/tests/stub-check.sh` (added by issue-2's phase 2,
  per `docs/issue-2/reports/implementation.md` item 5, "distributed... same
  as parse-check.sh").
- `customer-support/hooks/hooks.json` — registers only
  `directive.sh` under `SessionStart`. **No entry for `stub-check.sh`
  exists** — it was never wired as a hook, only invoked manually and its
  output pasted into the issue-2 record. So "hooks.json 등록이 있으면 함께
  제거" (issue body) has nothing to remove here.
- No wrapper/runner script in this repo calls `stub-check.sh` — issue-2's
  record shows it was run directly:
  `customer-support/hooks/tests/stub-check.sh customer-support`.

## Core canon basis (core #69)

- `docs/handbooks/canon-scripts.md` (core repo): "Canon scripts are
  referenced, never copied" — any script under `core/hooks/` or
  `core/hooks/tests/` is invoked via a path resolved against core's own
  plugin install root; a rulebook tree never holds a second copy.
- `core/hooks/tests/canon-manifest.txt`: lists 5 files, including
  `stub-check.sh` itself (self-referential — a vendored copy of
  stub-check.sh is itself something stub-check.sh's manifest-driven scan
  flags).
- `docs/handbooks/role-gates-tests.md` §"Canon invocation from a
  rulebook (issue-69)": the sanctioned invocation shape —

      "${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/stub-check.sh" "$(dirname "$0")/.."

  — first arg stays the rulebook directory to scan; the binary is never
  copied. Explicitly flags the `${CLAUDE_PLUGIN_ROOT}` sibling-resolution
  expression as unverified against a real marketplace install (verified
  only against core's own same-checkout sibling layout).
- `docs/issue-69/reports/implementation/reclaim-21-copies.md` (core
  repo): documents the rollout procedure for retiring 21 vendored copies
  across 43 rulebook repos — enumerate, delete-and-reference, verify
  per-repo, confirm the invocation line against one pilot repo before
  the other 20. This repo's `customer-support` is exactly one such copy;
  this issue is that pilot/one-repo instance of steps 2–3.

## Delta

Missing: deletion of the vendored file, and a phase-2 stub-check run
using the core-referenced invocation instead of the deleted local copy,
with the result recorded in `docs/issue-5/reports/implementation.md`.
No hooks.json change needed (nothing registers stub-check.sh there).
