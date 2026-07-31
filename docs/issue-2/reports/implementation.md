# Implementation record: core canon reference transition (issue-2)

Subject: issue-2. Phase 2 (execution), opened by issue comment
`APPROVE issue-2/implementation`.

loop_state: landed

## What was done

Executed the phase-2 write set from
`docs/issue-2/proposals/core-canon-reference-transition.md`: deleted the
vendored warrant-hunter agent and the three role-agnostic gate scripts
(plus their `hooks.json` registrations), rewrote `directive.sh` as a stub
over `core`'s shared `core_role_directive` function, added a copy of
`core/hooks/tests/stub-check.sh`, ran it, and recorded the result below.

## Why

Basis: on-the-record issue-2, whose body requires this repo to stop
vendoring copies of files core issue #63 (warrant plugin) and core issue
#66 (role-agnostic gates + `role-directive.sh`) promoted to canon, and to
reference the canon instead — reducing per-rulebook drift risk (the
issue-66 survey found 38/40 unique hashes across vendored copies).

## Upstream basis

- Core issue #63 / PR merged at `tokenmaxxxer-core` commit `130cb13`
  (warrant-hunt canon promotion) — `core/warrant` plugin now the
  canonical source for hunt-cadence behavior.
- Core issue #66 / PR merged at `tokenmaxxxer-core` commit `2fd1fcb`
  (role-agnostic gate promotion) — `core/hooks/hooks.json` registers
  `trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`
  globally; `core/hooks/lib/role-directive.sh` supplies
  `core_role_directive`; `core/hooks/tests/stub-check.sh` is the
  distributed drift check.
- `docs/issue-2/proposals/core-canon-reference-transition.md` (this
  repo, phase-1 PR #3, merged) — the approved plan this record executes.

## Changes (per proposal's phase-2 write set)

1. Deleted `customer-support/agents/warrant-hunter.md` — role now relies
   on the `warrant` plugin in the `tokenmaxxxer-core` marketplace
   (canonical source per core's own marketplace.json).
2. Deleted `customer-support/hooks/trailer-gate.sh`,
   `record-fields-gate.sh`, `handbook-trigger-gate.sh` and removed their
   `PreToolUse` registrations from `customer-support/hooks/hooks.json`.
   `core/hooks/hooks.json` (core issue #66, merged) already registers all
   three globally (`PreToolUse` matcher `.*`), so they still fire once
   `core` is enabled alongside this plugin.
3. Rewrote `customer-support/hooks/directive.sh` as a stub sourcing
   `core/hooks/lib/role-directive.sh` and calling `core_role_directive`
   with this role's four values (YOU DECIDE / USE WHEN / PRODUCES /
   HAND-OFF), verbatim from the prior directive.sh.
4. No `RECORD_FIELDS_TERMINAL_STATES` override added — confirmed (per
   proposal §4) this role has no non-default terminal `loop_state`.
5. Added `customer-support/hooks/tests/stub-check.sh`, a verbatim copy of
   `core/hooks/tests/stub-check.sh` (distributed per its own convention,
   same as `parse-check.sh`), and ran it against `customer-support/`.

## Open question resolved: directive.sh content gap (proposal §3)

Took option 2 from the proposal's three: **accept the drop**. This role's
`WRITE_SCOPE` was `[]` (nothing to preserve) and its `BOUNDARY CASE`
paragraph was generic hand-off advice already implied by the `HAND-OFF`
arrow — `core_role_directive`'s 4-arg shape has no slot for it and no
role-specific content was lost. The approval comment
(`APPROVE issue-2/implementation`) carried no prose answer, so this was
decided directly against the proposal's own stated defensibility
condition rather than left blocking.

The proposal's second open question (marketplace.json/plugin.json
companion-plugin declaration) was explicitly out of the phase-2 write set
unless requested; no such request was made, so it was left untouched.

## stub-check.sh result

Ran `customer-support/hooks/tests/stub-check.sh customer-support` from
the repo root:

```
stub-check: ok — no vendored 'trailer-gate.sh' under customer-support
stub-check: ok — no vendored 'record-fields-gate.sh' under customer-support
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under customer-support
stub-check: ok — no vendored 'parse-check.sh' under customer-support
stub-check: ok — customer-support/hooks/directive.sh is a role-directive stub
```

**PASS** (exit 0). Also manually ran the new `directive.sh` with
`CLAUDE_ROLE=customer-support` set and confirmed its output matches the
prior directive.sh's four fields (minus the dropped WRITE_SCOPE/BOUNDARY
CASE, per the resolved open question above).

Note: `core_role_directive`'s multi-line call form (one arg per line, as
shown in `role-directive.sh`'s own usage comment) fails stub-check.sh's
structural check — continuation lines match none of its allow-patterns
(comment/blank/shebang/`role-directive.sh`/`core_role_directive`/var
assignment) and are flagged as regrown boilerplate. Used a single-line
call instead; this is a stub-check.sh implementation detail worth a core
follow-up if other rulebooks migrating the same way hit it too.

## Ordering

Per the issue, this transition lands before this repo's own '룰북 성숙화'
issue's phase 2, per the issue's stated ordering constraint.

## Open findings

None. All five numbered tasks from issue-2 are complete and verified via
`stub-check.sh` (PASS).
