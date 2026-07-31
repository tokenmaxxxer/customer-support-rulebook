---
subject: issue-10
role: customer-support
loop_state: open
---

# Current-state survey (issue-10)

## Files read

- `customer-support/hooks/directive.sh` — sources core's
  `role-directive.sh`, one `core_role_directive` call with the fixed
  4-field shape (`YOU DECIDE / USE WHEN / PRODUCES / HAND-OFF`), same
  one-liner text since issue-1.
- `customer-support/hooks/hooks.json` — two hooks registered:
  `SessionStart` -> `directive.sh`; `PreToolUse` (matcher `.*`) ->
  core's `record-fields-gate.sh` (resolved against
  `CLAUDE_PLUGIN_ROOT_CORE`, canon-referenced, not copied). No other
  gate is registered.
- `customer-support/.claude-plugin/plugin.json` — plugin manifest, no
  `agents/` field, no `hooks/tests/` directory exists in this plugin
  tree at all.
- `customer-support/handbook.md` — the delivered phase-2 artifact from
  issue-1: priority/SLA table (6 columns, matches
  `docs/issue-1/proposals/customer-support.md` §2 exactly), escalation
  path (3 tiers, each with trigger/owner/timeout), 4 playbook
  scenarios (each with trigger/decision-criteria/script/escalation
  condition), an evidence-metric section (FCR/CSAT), and a 5-whys
  recurring-issue hand-off section.
- `docs/issue-1/proposals/customer-support.md` — the adopted
  methodology norms this issue must turn into enforcement. §1 defines
  the phase-1 3-artifact norm (survey -> scout-brief -> proposal, this
  document is instance 2 of that norm). §2 defines phase-2 output
  shape (SLA table 6 columns, escalation path tier/trigger/owner/
  timeout, playbook 4 elements/scenario, required evidence metric,
  5-whys recurring-issue check). §3 ties each element to a scout-brief
  source. §4 explicitly *defers* gate implementation ("Exact script
  name/location is left to phase-2 design... flagged as an open
  question") — this is the exact gap issue-10 exists to close.
- `docs/issue-1/reports/customer-support/scout-brief.md` — the sourced
  external research (ITIL, COPC, Atlassian/Rootly/Hyperping,
  Lorikeet/SourceCX) backing every §2 requirement. Not re-scouted here
  (see scout-brief.md's segment note); reused as-is per the issue's
  "채택 근거 문서를 규범 소스로 사용" constraint.
- `docs/specs/approvers.md` — unchanged from prior issues; approval
  path is single-account APPROVE-comment mode (confirmed: PR author
  and approver history is the same account across issue-1/2/5).

## What exists today (mechanically)

- **Directive**: one-line-per-field, no phase split, no per-facet
  judgment criteria, no prohibitions. Says *what* the role produces,
  not *how* to judge SLA-table/escalation-path/playbook conformance
  while producing it.
- **Gate**: `record-fields-gate.sh` (core canon) enforces contract §20
  generic record fields (what-was-done / why / upstream-basis /
  loop_state / open-findings) on `docs/issue-<n>/reports/
  customer-support.md` writes. It has **zero knowledge** of this
  role's own methodology (§2's SLA-table columns, escalation-path
  fields, playbook elements, evidence-metric requirement, 5-whys
  check). A record or handbook write that omits every §2 element
  today passes every existing gate.
- **Ordering**: the phase-1 3-artifact norm (survey before scout-brief
  before proposal) is stated in prose (§1) but has **no mechanical
  enforcement** — nothing currently blocks writing a proposal before a
  survey exists, other than habit.
- **Tests**: no `customer-support/hooks/tests/` directory exists; no
  gate-pass/gate-deny test cases for this role anywhere in this repo.
- **Agents/checklist**: no `customer-support/agents/` directory; the
  5-whys procedure is prose inside `handbook.md` §5 with no
  machine-checkable trigger tying "a scenario flags a repeat pattern"
  to "the 5-whys questions were actually answered before the hand-off
  decision."

## Delta this issue must fill

1. Deepen `directive.sh`'s content (still the fixed 4-field
   `core_role_directive` call — core's shared lib signature is
   out of scope to change, contract's role-boundary is unchanged) with
   phase-1/phase-2 step-by-step judgment criteria and prohibitions per
   facet (SLA table / escalation path / playbook / evidence metric /
   5-whys), OR add a second, richer directive-shaped hook alongside it
   (precedent: `warrant/hooks/directive.sh` emits a multi-section
   heredoc directly, not through `core_role_directive` — see
   scout-brief.md).
2. A methodology gate, this role's own (not core canon — §2's SLA/
   escalation/playbook/metric/5-whys shape is customer-support-
   specific, same category as `pricing/hooks/methodology-gate.sh`
   which is pricing-specific and lives in the pricing plugin, not
   core), mechanically checking §2's required elements on this role's
   write surfaces (`handbook.md`, `docs/issue-<n>/reports/
   customer-support.md`).
3. Order enforcement for the phase-1 3-artifact norm, if a mechanism
   is warranted beyond the existing phase-gate (this survey evaluates
   that in the proposal; the phase-1/phase-2 split is already
   mechanically enforced by `approval-gate.sh`/`board-gate.sh` per the
   handoff contract, so the *inner* survey->scout-brief->proposal order
   is the only genuinely new ordering question).
4. Gate tests under this repo's root `tests/` (per the issue's
   instruction — "레포 루트 tests" — not `customer-support/hooks/tests/`;
   confirmed no root `tests/` directory exists yet either).
5. A 5-whys checklist artifact if the repeated procedure warrants one
   beyond prose in `handbook.md` §5, per the issue's "필요 시" clause.

## Canon constraint check

`docs/handbooks/canon-scripts.md` (core, referenced not copied) is
this repo's binding rule: any script under `core/hooks/` is invoked by
path against the core plugin's install root, never vendored. This
role's methodology gate is **role-specific business logic**, not a
core canon script — it is new content under `customer-support/hooks/`,
analogous to `pricing/hooks/methodology-gate.sh` living under
`pricing/hooks/`, not to `record-fields-gate.sh` living under
`core/hooks/`. No canon file is copied by this issue's proposal.
