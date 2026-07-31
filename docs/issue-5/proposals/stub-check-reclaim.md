# Proposal: stub-check.sh canon reclaim (issue-5)

Subject: issue-5. Phase 1 only — no files under `customer-support/` are
edited in this PR. See
`docs/issue-5/reports/implementation/survey.md` for the current-state
survey this is based on.

## Basis

Core issue #69 canon (`docs/handbooks/canon-scripts.md`, core repo):
canon scripts are referenced, never copied. `stub-check.sh` is itself on
`core/hooks/tests/canon-manifest.txt` — a vendored copy of it is exactly
the drift it is built to catch in other files.

## Delete

`customer-support/hooks/tests/stub-check.sh` (verbatim copy of
`core/hooks/tests/stub-check.sh`, added by issue-2's phase 2).

## hooks.json

No change. Surveyed `customer-support/hooks/hooks.json`: it registers
only `directive.sh` under `SessionStart`; `stub-check.sh` was never
wired as a hook entry, only invoked manually. Issue body's "hooks.json
등록이 있으면 함께 제거" has no target here.

## Phase-2 invocation (record only, not run in this PR)

Per `docs/handbooks/role-gates-tests.md` §"Canon invocation from a
rulebook (issue-69)", the core-referenced call, from repo root:

```bash
"${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}/hooks/tests/stub-check.sh" customer-support
```

`$CLAUDE_PLUGIN_ROOT` resolves to this plugin's own install root at hook
runtime; there is no such variable in a plain shell invocation from repo
root, so phase 2 resolves the path directly against wherever `core` is
checked out as a sibling in this workspace (mirroring the same-checkout
layout core's own docs verify against) and records the concrete path
used, since core's own docs flag the `${CLAUDE_PLUGIN_ROOT}` sibling
expression as unverified against a real marketplace install. Phase 2
records the invocation and its pass/fail output in
`docs/issue-5/reports/implementation.md` — no second copy of the script
is added to satisfy the run.

## Phase-2 write set

- `customer-support/hooks/tests/stub-check.sh` — delete
- `docs/issue-5/reports/implementation.md` — new, phase-2 record
  (core-referenced stub-check.sh invocation + result)

## Open question for approver

Core's own docs (`role-gates-tests.md`) flag the exact
`${CLAUDE_PLUGIN_ROOT}` sibling-resolution expression as unverified
against a real marketplace install. This repo's phase 2 will resolve
`core`'s path directly (same-checkout sibling, matching how core's own
test run is verified) rather than depend on the unverified expression.
If the approver wants the exact expression from
`role-gates-tests.md` used verbatim instead (accepting its noted
uncertainty), say so; otherwise phase 2 proceeds with the
same-checkout resolution and notes the concrete path in the record.

This PR is phase-1 (proposal) only. Phase 2 opens only after an
approvers.md account's PR-review Approve, or the exact-string
`APPROVE issue-5/implementation` issue comment.
