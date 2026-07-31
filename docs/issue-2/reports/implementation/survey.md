# Survey: issue-2 — core canon reference transition

Subject: issue-2

## Scope

Issue #2 asks this rulebook to stop vendoring copies of content that now
has a single canon in `tokenmaxxxer-core`, and reference core instead.
Six files in this repo are affected by the issue's five numbered tasks.

## Current-state inventory

| # | Issue item | File(s) today | What core canon now provides |
|---|---|---|---|
| 1 | Remove warrant-hunter copy | `customer-support/agents/warrant-hunter.md` (role-adapted copy of the generic warrant-hunter agent) | `warrant` plugin in core marketplace ships the canonical `agents/warrant-hunter.md`. Core marketplace.json states explicitly: "Canonical source for this plugin; role rulebooks reference it rather than vendoring a copy." |
| 2 | Remove role-agnostic gate copies + registrations | `customer-support/hooks/trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`; matching PreToolUse entries in `customer-support/hooks/hooks.json` | `core/hooks/*-gate.sh` are parameterized on `CLAUDE_ROLE` and registered globally by `core/hooks/hooks.json` (PreToolUse matcher `.*`). Once `core` is enabled alongside `customer-support`, these already fire — no local copy or registration needed. |
| 3 | Replace directive.sh with stub | `customer-support/hooks/directive.sh` (full boilerplate: trap/kill-switch/CLAUDE_ROLE guard/heredoc, kill switch `CUSTOMER_SUPPORT_CYCLE_OFF`) | `core/hooks/lib/role-directive.sh` exposes `core_role_directive <you_decide> <use_when> <produces> <hand_off>`, handling trap/kill-switch (`${ROLE_UPPER}_CYCLE_OFF`)/guard/heredoc. Role-unique text becomes the 4 args. |
| 4 | Preserve real role-specific terminal loop_state via `RECORD_FIELDS_TERMINAL_STATES` | n/a — checked | No `roles/customer-support.json` or other role-state file exists in this repo. No evidence this role uses a non-default terminal `loop_state`. Core's default is `landed` via `RECORD_FIELDS_TERMINAL_STATES="${RECORD_FIELDS_TERMINAL_STATES:-landed}"`. **Finding: no override needed — nothing to preserve.** |
| 5 | Record stub-check.sh pass | (phase 2 record, not yet written) | `core/hooks/tests/stub-check.sh [hooks-dir]` — fails on any vendored `trailer-gate.sh`/`record-fields-gate.sh`/`handbook-trigger-gate.sh`/`parse-check.sh` under the given dir (maxdepth 3), and structurally validates any `directive.sh` found (must source `role-directive.sh`, call `core_role_directive`, and contain no other non-blank/non-comment lines). This is the acceptance check for items 1-3. |

## Content gap flagged (item 3)

`customer-support/hooks/directive.sh` currently carries a bespoke
"BOUNDARY CASE" paragraph and a `WRITE_SCOPE([])` line that the shared
`core_role_directive` function's 4-argument/heredoc shape does not have
room for. This content must not be silently dropped — see proposal's
open questions.

## Scout: SKIP

This is a pure internal repo-canon migration governed entirely by the
issue's 5 numbered steps and core's own migration tooling/docstrings
(`stub-check.sh`, `role-directive.sh`); the two open design points
(directive-shape gap, marketplace companion-plugin declaration) are
resolved by reading core canon directly, not by scouting an external
market/product field — so scouting is skipped.

## Other findings

- **No local migrated exemplar exists.** `implementation-rulebook/coding/`
  (checked as a candidate "after" reference) still vendors its own
  `trailer-gate.sh`/`record-fields-gate.sh`/`handbook-trigger-gate.sh` and
  `agents/warrant-hunter.md`, and its `directive.sh` is still full
  boilerplate. This may be the first rulebook to make this transition;
  the proposal is derived directly from core canon, not copied from a
  precedent.
- Root `.claude-plugin/marketplace.json` in this repo lists only the
  `customer-support` plugin, with no reference to `core`/`warrant` as
  companion plugins. Issue #2's 5 tasks do not mention marketplace.json.
  Flagged as an open question in the proposal, not decided here.
