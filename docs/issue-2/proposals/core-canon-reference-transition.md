# Proposal: core canon reference transition (issue-2)

Subject: issue-2

Phase 1 only. This proposal maps each of issue #2's 5 numbered tasks to
a concrete phase-2 change. No hooks/agents files are edited in this PR;
see `docs/issue-2/reports/implementation/survey.md` for the current-state
survey this proposal is based on.

## 1. Remove warrant-hunter copy

Delete `customer-support/agents/warrant-hunter.md`. Rely on the `warrant`
plugin from the `tokenmaxxxer-core` marketplace (core marketplace.json:
"Canonical source for this plugin; role rulebooks reference it rather
than vendoring a copy") being installed/enabled alongside
`customer-support`. No role-specific hunt-cadence directive text exists
elsewhere in this repo to migrate.

## 2. Remove role-agnostic gate copies + registrations

Delete:
- `customer-support/hooks/trailer-gate.sh`
- `customer-support/hooks/record-fields-gate.sh`
- `customer-support/hooks/handbook-trigger-gate.sh`

Edit `customer-support/hooks/hooks.json` to remove the PreToolUse entries
that register these three (the `(Write|Edit|MultiEdit|NotebookEdit)` →
record-fields-gate.sh entry, and the `Bash` → handbook-trigger-gate.sh +
trailer-gate.sh entry). `core/hooks/hooks.json` already registers all
three globally (PreToolUse matcher `.*`, parameterized on `CLAUDE_ROLE`),
so once `core` is enabled these fire without a local copy.

## 3. Replace directive.sh with a stub

Replace `customer-support/hooks/directive.sh` (currently full boilerplate:
trap/kill-switch/CLAUDE_ROLE guard/heredoc) with:

```bash
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive \
  "YOU DECIDE: 문의를 어떤 우선순위/SLA로 처리할지" \
  "USE WHEN: CS 플로우/SLA 설계가 걸릴 때" \
  "PRODUCES: support playbook, SLA table, escalation path" \
  "HAND-OFF: 반복 문의가 제품 결함이면 → product-discovery"
```

This preserves the four required fields verbatim from the current
directive.sh. The kill switch (`CUSTOMER_SUPPORT_CYCLE_OFF`) and
CLAUDE_ROLE guard are handled automatically by `core_role_directive` via
`${ROLE_UPPER}_CYCLE_OFF` — no hand-rolled case statement needed.

**Content gap — needs reviewer input.** The current directive.sh also
carries a `WRITE_SCOPE: []` line and a "BOUNDARY CASE" paragraph:

> BOUNDARY CASE: if the work in front of you drifts outside `decides`
> above, stop and hand off per the arrow — do not silently absorb another
> role's scope. Record the hand-off point in this role's record before
> opening the next role's session.

`core_role_directive`'s 4-arg/heredoc shape has no slot for this. This
content must not be silently dropped. Three options, not decided here:
1. Fold the BOUNDARY CASE text (and WRITE_SCOPE, if non-empty) into the
   `hand_off` argument as trailing text.
2. Accept the shared function's shape drops WRITE_SCOPE/BOUNDARY CASE
   for this role (defensible if this role's WRITE_SCOPE is `[]` — i.e.
   nothing — and BOUNDARY CASE is generic advice already implied by
   the hand-off arrow).
3. Open a core follow-up issue to extend `core_role_directive`'s
   signature/heredoc shape to include an optional boundary-case slot.

## 4. RECORD_FIELDS_TERMINAL_STATES

Checked: no `roles/customer-support.json` or other role-state file
exists in this repo, and no evidence this role's record finishes at a
non-default `loop_state`. Core's default terminal state is `landed`.
**No `RECORD_FIELDS_TERMINAL_STATES` override is added** — there is
nothing role-specific to preserve.

## 5. stub-check.sh record

Phase 2 will run `core/hooks/tests/stub-check.sh` (or a repo-relative
distributed copy, per its own distribution convention) against
`customer-support/` and record the pass/fail result in
`docs/issue-2/reports/implementation.md`. This record write happens only
in phase 2, per contract v3 s19 — not in this phase-1 PR.

## Ordering constraint

Per the issue, this transition must land before this repo's own
'룰북 성숙화' issue's phase 2.

## Phase-2 write set

- `customer-support/agents/warrant-hunter.md` — delete
- `customer-support/hooks/trailer-gate.sh` — delete
- `customer-support/hooks/record-fields-gate.sh` — delete
- `customer-support/hooks/handbook-trigger-gate.sh` — delete
- `customer-support/hooks/hooks.json` — edit (remove the 3 gate registrations)
- `customer-support/hooks/directive.sh` — rewrite as stub (see §3)
- `docs/issue-2/reports/implementation.md` — new, phase-2 record (stub-check.sh result)

## Open questions for approver

1. **directive.sh content gap (§3):** which of the 3 options above for
   WRITE_SCOPE/BOUNDARY CASE — fold into hand_off, accept the drop, or
   file a core follow-up issue?
2. **marketplace.json / plugin.json companion declaration:** should root
   `.claude-plugin/marketplace.json` (or `customer-support/.claude-plugin/plugin.json`)
   be updated to declare `core` and `warrant` as required/companion
   plugins, the way `implementation-rulebook`'s coding plugin lists its
   same-repo companions? Issue #2's 5 tasks don't mention this, and it's
   a cross-repo/cross-marketplace declaration (not a same-repo one), so
   it is left open rather than decided here. Not part of the phase-2
   write set above unless the approver asks for it.

This PR is phase-1 (proposal) only. Phase 2 opens only after an
approvers.md account's PR-review Approve, or the exact-string
`APPROVE issue-2/implementation` issue comment.
