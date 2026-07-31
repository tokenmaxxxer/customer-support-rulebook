# Proposal: enforce the adopted methodology as plugin machinery (issue-10)

Subject: issue-10. Phase 1 only — no file under `customer-support/` is
edited in this PR; the scripts below are specified in full but not
committed until an Approve opens phase 2. Basis:
`docs/issue-10/reports/customer-support/survey.md` (current-state) and
`docs/issue-10/reports/customer-support/scout-brief.md` (internal
precedent — `pricing/hooks/methodology-gate.sh`, core's
`record-fields-gate.sh`, `warrant`'s state/directive scripts). Norm
source: `docs/issue-1/proposals/customer-support.md` (the adopted
methodology this issue enforces) — no new external methodology claim
is made here; every requirement below cites back to that document's
§2/§3.

## 1. Directive deepening (phase 1 / phase 2, facet-level)

`core_role_directive`'s call shape is unchanged (core's shared lib
signature — `role-directive.sh`'s 4 positional args — is out of scope;
role boundaries are unchanged). What changes is a **second**
SessionStart hook, `customer-support/hooks/methodology-directive.sh`,
heredoc-emitting a facet-level protocol block — the shape
`warrant/hooks/directive.sh` already uses for content too rich for 4
one-line fields (scout-brief must-be #3/adopt). Registered in
`hooks.json`'s existing `SessionStart` array, after `directive.sh`.

Content (verbatim script body, phase 2 write):

```
#!/usr/bin/env bash
# SessionStart hook: methodology-facet deepening on top of directive.sh's
# 4-field summary. Kill switch: export CUSTOMER_SUPPORT_METHODOLOGY_OFF=1
case "${CUSTOMER_SUPPORT_METHODOLOGY_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac
[ "${CLAUDE_ROLE:-}" = "customer-support" ] || exit 0

cat <<'EOF'
<customer-support-methodology priority="high">
Per docs/issue-1/proposals/customer-support.md (adopted methodology).

PHASE 1 (proposal, this issue's own norm — bootstrapped by
docs/issue-1/proposals/customer-support.md itself):
- Produce exactly 3 artifacts in order: survey.md (read the actual
  current directive.sh/hooks.json/handbook.md/record — no proposal
  claims a gap it did not check), scout-brief.md (sourced, cite
  file/URL per claim), proposals/customer-support.md (ties every
  adopted element back to a scout-brief must-be/source, never asserted
  independently).
- PROHIBITED: proposing a §2 structural change (SLA columns,
  escalation fields, playbook elements, evidence metric, 5-whys) with
  no scout-brief citation backing it. An uncited structural claim is a
  guess, not an adoption.

PHASE 2 (delivery), per facet:
- SLA table: every row must be Impact x Urgency -> tier (derived, not
  asserted); all 6 columns present (tier, impact, urgency, first-
  response target, resolution target, escalation-trigger time).
  JUDGMENT: a tier with no impact/urgency pair behind it fails this
  norm even if a plausible-looking tier label is present.
- Escalation path: every tier states trigger condition + named owner
  (a role/title, never "the team") + timeout. PROHIBITED: a bare
  "escalate to manager if unresolved" line.
- Playbook scenario: trigger/scenario + decision criteria (referencing
  the impact/urgency matrix) + script/response template + escalation
  condition (naming the specific escalation-path tier). PROHIBITED: a
  script with no escalation condition, or an escalation condition that
  doesn't name a tier defined above.
- Evidence metric: at least one of CSAT/FCR/SLA-adherence named and
  tied to what the deliverable does to move it. PROHIBITED: citing a
  metric by name with no sentence connecting it to the design.
- 5-whys: any scenario/entry describing a *repeat* inbound pattern
  must answer all 5 questions (docs/issue-1 handbook.md §5 shape)
  before stating a hand-off-vs-keep decision. PROHIBITED: writing
  "hand off to product-discovery" for a flagged-repeat entry with no
  5-whys answers preceding it in the same entry.
- Record (docs/issue-<n>/reports/customer-support.md): on top of
  contract §20's generic fields (record-fields-gate.sh, core canon,
  unchanged), state which evidence metric(s) were cited and confirm
  the SLA-table/escalation-path structural checks above passed for the
  delivered content.

These facet rules are what methodology-gate.sh (customer-support's own,
role-local) checks mechanically on write. This directive states the
judgment; the gate states the floor.
</customer-support-methodology>
EOF
exit 0
```

## 2. Methodology gate (mechanical enforcement)

New file, phase 2: `customer-support/hooks/methodology-gate.sh`.
Role-local (not core canon — this role's SLA/escalation/playbook shape
is customer-support-specific business logic, the same category as
`pricing/hooks/methodology-gate.sh`, which lives in `pricing/hooks/`,
not `core/hooks/`; per `docs/handbooks/canon-scripts.md` nothing here
is a vendored copy of a core file). Structurally mirrors
`pricing/hooks/methodology-gate.sh` (same fail-closed trap, same
kill-switch pattern, same PreToolUse Write/Edit/MultiEdit
new-content-reconstruction approach) — referenced as a design pattern,
not copied byte-for-byte (its checked elements are entirely
customer-support-specific).

**Target write surfaces** (regex, scoped — nothing outside these paths
is this gate's business):
- `customer-support/handbook.md` (or whatever path phase 2 chooses for
  the combined deliverable — regex: `^customer-support/handbook\.md$`
  plus `^docs/issue-[0-9]+/(_assets|reports)/customer-support/.*\.md$`
  if phase 2 splits the deliverable into per-issue files; exact path
  decided by phase 2, same open question `docs/issue-1/proposals/
  customer-support.md` already flagged and left open — not re-decided
  here)
- `^docs/issue-[0-9]+/reports/customer-support\.md$` (the record)

**Kill switch**: `CUSTOMER_SUPPORT_METHODOLOGY_GATE_OFF=1`.

**Required elements checked** (substring/regex on resolved new
content, `has_any`-style like `pricing/hooks/methodology-gate.sh`):

1. **SLA-table structural check**: a markdown table header containing
   all 6 required column labels (case-insensitive: "priority", one of
   "impact", one of "urgency", "first response", "resolution",
   "escalation trigger"). Missing any -> `missing.append("sla-table-column:<name>")`.
2. **Escalation-path field check**: for text under an "escalation
   path" heading, each tier row/block must contain "trigger" (or
   equivalent condition language), a named owner (non-generic — "the
   team" alone does not satisfy; require presence of a role/title-
   shaped token, checked as: a capitalized noun phrase adjacent to
   "owner:" or a table column so labeled), and "timeout" (or
   equivalent). Missing -> `missing.append("escalation-field:<name>")`.
3. **Playbook-scenario element check**: for each detected scenario
   block (heading matching `Scenario` or a bullet list under
   "playbook"), require presence of "trigger"/"scenario", "decision
   criteria", "script" or "response template" or "response", and
   "escalation condition". Missing any in a detected scenario block ->
   `missing.append("playbook-element:<name>")`.
4. **Evidence-metric check**: at least one of "csat", "fcr", "first
   contact resolution", "sla-adherence", "sla adherence" present.
   Missing -> `missing.append("evidence-metric")`.
5. **5-whys check**: fires only when the new content contains
   "repeat" or "recurring" language in a scenario/entry context; when
   it does, require "5-whys" (or "five whys") plus 5 distinct
   numbered/bulleted question-shaped lines nearby (heuristic: at least
   5 lines ending in `?` within the same section). Missing ->
   `missing.append("5-whys-check")`. This mirrors §2's "Recurring-issue
   hand-off" norm being conditional (only fires when a repeat pattern
   is actually described), same conditional-check shape
   `pricing/hooks/methodology-gate.sh` uses for its "labeled-numbers"
   check (only fires when digits are present).

Deny message: `"customer-support: refused — methodology write is
missing required element(s): <list>. Per docs/issue-1/proposals/
customer-support.md §2, every phase-2 deliverable/record write must
carry: <full requirement text>."` — same specificity-per-element shape
as both precedent gates (scout-brief performance axis #1).

Internal-error/unparseable-payload paths fail closed (`exit 2`),
matching both precedent gates exactly.

## 3. Ordering (state tracking) — not added, reasoned

Per scout-brief's skip pattern: the phase-1 3-artifact order
(survey -> scout-brief -> proposal) is a same-PR, same-session
sequence with no cross-session gap, and the phase-1/phase-2 boundary
itself is already mechanically enforced by core's `approval-gate.sh`/
`board-gate.sh` (unchanged, out of scope here). A `warrant`-style
SessionStart state-rebuild script exists to solve a problem
(`approved`-but-interrupted work spanning session restarts) this
role's 3-artifact order does not have. Adding one would be
disproportionate machinery for a within-one-PR document sequence.
**No state-tracking script is proposed.** If a future issue finds
proposals actually being written before surveys exist in practice, a
lightweight PreToolUse check (proposal write blocked unless
survey.md/scout-brief.md already exist on disk under the same
`docs/issue-<n>/` path) can be added to `methodology-gate.sh` itself
as one more `has_any`-style branch — flagged as a future extension
point, not built now absent evidence of the failure it would prevent.

## 4. Gate tests

Per the issue's explicit instruction ("레포 루트 tests"), new file:
`tests/methodology-gate-tests.sh` (repo root, not
`customer-support/hooks/tests/` — no such directory exists today and
the issue names the root location). Runs the gate as a real
subprocess, same invocation model as core's
`run-role-gates-tests.sh`: feeds a synthetic PreToolUse JSON payload
(`tool_name`, `tool_input.file_path`, `tool_input.content`) on stdin
with `CLAUDE_ROLE=customer-support` and `CLAUDE_PROJECT_DIR` set to a
temp git-initialized dir.

**Pass cases:**
- Full `handbook.md`-shaped content (all 6 SLA columns, all 3
  escalation fields per tier, all 4 playbook elements per scenario, an
  evidence metric, a repeat-pattern scenario with 5-whys present) ->
  exit 0.
- A record write with no repeat-pattern language and no SLA/escalation
  content at all (not a methodology-shaped write) -> exit 0 (gate is
  scoped to detected structural content, not every record write).
- `CUSTOMER_SUPPORT_METHODOLOGY_GATE_OFF=1` set -> exit 0 regardless of
  content (kill-switch check).

**Deny cases** (one per required element, each isolated by starting
from the full pass-case fixture and removing exactly one element):
- SLA table missing the "escalation trigger" column -> exit 2,
  message contains `sla-table-column`.
- Escalation tier with no named owner (only "the team") -> exit 2,
  message contains `escalation-field`.
- Playbook scenario with no escalation condition -> exit 2, message
  contains `playbook-element`.
- Full handbook content with the evidence-metric section deleted ->
  exit 2, message contains `evidence-metric`.
- A "recurring"-flagged scenario with no 5-whys questions -> exit 2,
  message contains `5-whys-check`.
- Malformed JSON on stdin -> exit 2 (fail-closed on unparseable
  payload).
- A Bash tool_name (not Write/Edit/MultiEdit) targeting `handbook.md`
  -> exit 0 (out of this gate's scope, same as both precedent gates).

Wired into a root `tests/run-all.sh` if/when more root-level test
files exist; for now `tests/methodology-gate-tests.sh` is
directly runnable (`bash tests/methodology-gate-tests.sh`), matching
`role-gates-tests.md`'s "no setup required" precedent.

## 5. Checklist for the 5-whys repeated procedure

The 5-whys check is a repeated, per-entry procedure (facet 5 above),
not a one-time judgment — warrants a standalone checklist per the
issue's "필요 시" clause, so an agent (or human) filling out a new
recurring-pattern playbook entry has the exact 5 questions to hand
without re-deriving them from `handbook.md` §5's prose each time. New
file, phase 2: `customer-support/checklists/5-whys-recurring.md`,
verbatim-copying the 5 questions already adopted in `docs/issue-1/
proposals/customer-support.md` §2 / `handbook.md` §5 (same content,
promoted from embedded prose to a referenceable checklist — not a new
methodology claim). `methodology-directive.sh` (§1 above) references
this file by path in its 5-whys facet line. No `agents/` addition is
proposed: the procedure is a content-authoring checklist, not a task
an autonomous subagent runs independently (unlike, e.g., `warrant`'s
hunt dispatch, which has no analog in this role's deliverable shape).

## Phase-2 write set

- `customer-support/hooks/methodology-directive.sh` — new (§1)
- `customer-support/hooks/hooks.json` — edit, register the new
  SessionStart hook (§1)
- `customer-support/hooks/methodology-gate.sh` — new (§2)
- `customer-support/hooks/hooks.json` — edit, register the new
  PreToolUse gate alongside the existing `record-fields-gate.sh` entry
  (§2)
- `tests/methodology-gate-tests.sh` — new (§4)
- `customer-support/checklists/5-whys-recurring.md` — new (§5)
- `docs/issue-10/reports/customer-support.md` — new, phase-2 record

No change to `customer-support/hooks/directive.sh` (4-field call
shape unchanged, per §1) and no change to core (`record-fields-gate.sh`
stays canon-referenced, unmodified, per the issue's canon-reference-
only constraint).

## Open questions for approver

1. **Deliverable file path**, carried over unresolved from
   `docs/issue-1/proposals/customer-support.md`'s open question 1:
   this proposal's gate regex (§2) covers both the current single-file
   `handbook.md` and a possible future per-issue split
   (`docs/issue-<n>/reports/customer-support/*.md`). If phase 2
   changes the deliverable location, the gate's target-path regex is
   the only thing that needs updating — flagged so the approver can
   confirm the regex shape covers the intended path before phase 2
   builds against it.
2. **5-whys detection heuristic** (§2 point 5): "5 lines ending in `?`
   within the same section" is a heuristic, not a semantic check — a
   determined writer could satisfy it with 5 unrelated questions. This
   is the same class of trade-off `pricing/hooks/methodology-gate.sh`
   accepts for its own substring checks (a gate checks presence of
   required *shape*, not correctness of *content* — content
   correctness is a review-time judgment, not a PreToolUse-gate-time
   one). Flagged for approver awareness, not proposed as a blocker.

This PR is phase-1 (proposal) only. Phase 2 opens only after an
approvers.md account's PR-review Approve, or the exact-string
`APPROVE issue-10/customer-support` issue comment.
