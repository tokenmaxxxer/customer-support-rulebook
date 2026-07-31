# Implementation record: stub-check.sh canon reclaim (issue-5)

Subject: issue-5. Phase 2 (execution), opened by issue comment
`APPROVE issue-5/implementation`.

loop_state: landed

## What was done

Executed the phase-2 write set from
`docs/issue-5/proposals/stub-check-reclaim.md`: deleted the vendored
`customer-support/hooks/tests/stub-check.sh`, confirmed
`customer-support/hooks/hooks.json` has no `stub-check.sh` registration to
remove, ran core's canonical `stub-check.sh` referenced (not copied)
against this rulebook, and recorded the result below.

## Why

Basis: on-the-record issue-5, which requires this repo to stop vendoring
a copy of `stub-check.sh` per core issue #69 canon
(`docs/handbooks/canon-scripts.md`, core repo) — canon scripts are
referenced, never copied, and `stub-check.sh` itself is on
`core/hooks/tests/canon-manifest.txt`, making a vendored copy of it
exactly the drift it exists to catch elsewhere.

## Upstream basis

- Core issue #69 / delivered at `tokenmaxxxer-core` commit `2aa1ab4`
  ("deliver(implementation): pin stub-check to core, ban rulebook copies,
  reclaim 21 duplicates (issue-69)") — canon requires reference execution
  of `core/hooks/tests/stub-check.sh`, no rulebook copy.
- `docs/issue-5/proposals/stub-check-reclaim.md` (this repo, phase-1 PR
  #6, merged) — the approved plan this record executes.

## Changes (per proposal's phase-2 write set)

1. Deleted `customer-support/hooks/tests/stub-check.sh` (verbatim copy of
   `core/hooks/tests/stub-check.sh`, added by issue-2's phase 2).
2. `customer-support/hooks/hooks.json` unchanged — reconfirmed at
   execution time it registers only `directive.sh` under `SessionStart`;
   `stub-check.sh` was never wired as a hook entry, only invoked
   manually, so there was nothing to remove.

## Open question resolved: core path resolution (proposal's open question)

The proposal flagged that core's own docs mark the
`${CLAUDE_PLUGIN_ROOT}/../core` sibling expression as unverified against
a real marketplace install, and proposed resolving `core`'s path directly
against a same-checkout sibling instead. The approval comment carried no
prose answer, so phase 2 proceeded with the proposal's own default
(same-checkout resolution). This workspace has no plain `core` directory
sibling to this rulebook checkout; the concrete path used is this
platform's own core delivery checkout for canon issue #69:
`tokenmaxxxer-core-issue-69-implementation/core`, branch
`issue-69/implementation`, commit `2aa1ab4` (the same commit as the
"Upstream basis" entry above — the delivery that pinned `stub-check.sh`
as canon).

## stub-check.sh result

Ran, from this repo's root:

```bash
CORE_PLUGIN_ROOT=/home/jwjung/.tokenmaxxxer/work/tokenmaxxxer-core-issue-69-implementation/core
"$CORE_PLUGIN_ROOT/hooks/tests/stub-check.sh" customer-support
```

```
stub-check: ok — no vendored 'trailer-gate.sh' under customer-support
stub-check: ok — no vendored 'record-fields-gate.sh' under customer-support
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under customer-support
stub-check: ok — no vendored 'parse-check.sh' under customer-support
stub-check: ok — no vendored 'stub-check.sh' under customer-support
stub-check: ok — customer-support/hooks/directive.sh is a role-directive stub
```

**PASS** (exit 0). No second copy of `stub-check.sh` was added to this
repo to satisfy the run — the invocation runs against core's own checkout
each time.

## Open findings

None. Both numbered items in the proposal's phase-2 write set are
complete and verified via the core-referenced `stub-check.sh` run
(PASS).
