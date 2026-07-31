# Proposal: customer-support domain methodology norms (issue-1)

Subject: issue-1. Phase 1 only — no file under `customer-support/` is
edited in this PR. Basis:
`docs/issue-1/reports/customer-support/survey.md` (current-state) and
`docs/issue-1/reports/customer-support/scout-brief.md` (external
methodology research, sources cited there).

## 1. Phase-1 제안서 규범

Every future customer-support phase-1 proposal in this repo must
produce exactly these three artifacts, in this order, and this
proposal is itself the first instance (bootstrapping the norm by
example):

1. **`docs/issue-<n>/reports/customer-support/survey.md`** — current-state
   survey. Required frontmatter: `subject: issue-<n>`,
   `role: customer-support`, `loop_state: open`. Body must read the
   actual current files (`directive.sh`, `hooks.json`, `plugin.json`,
   any record/handbook file) and state a "Delta this issue must fill"
   section — no proposal may claim a gap without having checked the
   current file state first.
2. **`docs/issue-<n>/reports/customer-support/scout-brief.md`** — external
   methodology research, per the scout-directive protocol (survey →
   parallel sweep → ≤2 deepening stages, capped at 5 stages, judged by
   saturation). Required sections: must-bes (Kano), 2-3 performance
   axes, one adopt/one skip pattern with reasoning, a segment-fit line
   (why this repo's role is/isn't the same segment as the source
   domain's canonical org shape), a GAP LINE (current role state vs.
   missing), stage count/mode used, and a `Sources:` list. **No source,
   no claim** — anything not backed by a fetched/searched source must
   be labeled an explicit assumption, not stated as researched fact.
3. **`docs/issue-<n>/proposals/customer-support.md`** — the proposal
   itself, structured as this document is: 채택 근거 tied back to
   scout-brief must-bes/sources (not asserted independently), a
   concrete phase-2 write set, and an open-questions section only if
   genuine open questions exist.

**Evidence/citation format**: every adopted methodology claim in the
채택 근거 section must name the source domain/standard (e.g. "ITIL
priority matrix", "COPC CX Standard") and the specific scout-brief
must-be/axis it satisfies — not a bare footnote link with no
connective reasoning to this role's stated decision.

## 2. Phase-2 산출물 규범

The delivered support playbook / SLA table / escalation path
(`customer-support`'s stated PRODUCES) must contain the following
structural components. This is the acceptance shape phase-2 output is
checked against — see §4 gate.

### SLA table — required columns

| Column | Required | Basis |
|---|---|---|
| Priority tier (e.g. P1–P4) | yes | ITIL impact×urgency matrix output |
| Impact rating | yes | one axis of the priority derivation, not folded into tier alone |
| Urgency rating | yes | other axis — tier must be derivable from impact×urgency, not asserted directly |
| First response time target | yes | COPC CX / ITIL SLA convention |
| Resolution time target | yes | same |
| Escalation trigger time | yes | time past which an unresolved ticket at this tier auto-escalates (PagerDuty/ITIL convention) |

A table with only "priority" and "resolution time" columns (no
impact/urgency derivation, no escalation trigger time) does not meet
this norm.

### Escalation path — required structure

- **Tier levels** (e.g. L1/L2/L3 or named owner roles), each with:
  - **Trigger condition** (what makes a ticket escalate to this tier —
    time-based per SLA table, or severity-based)
  - **Owner** (named role/person, not "the team")
  - **Timeout** (how long this tier has before escalating further)

A bare "escalate to manager if unresolved" line does not meet this
norm — tier/trigger/owner/timeout must each be explicit, per
playbook-practice convention (Atlassian/Rootly/Hyperping escalation
policy structure).

### Support playbook — required elements per scenario entry

- **Trigger/scenario** — what inbound pattern this entry covers
- **Decision criteria** — how to classify it against the priority
  matrix (impact/urgency inputs)
- **Script/response template** — the actual customer-facing text or
  structured response guidance
- **Escalation condition** — when this scenario routes out of the
  playbook into the escalation path (explicit link to §escalation path
  tiers, not restated ad hoc)

### Required evidence metric

Every phase-2 deliverable must cite at least one of CSAT, FCR, or
SLA-adherence rate as the metric the playbook/SLA table is designed to
move, per scout-brief's must-be #4 (FCR as strongest CSAT predictor)
and performance axis #1 (CSAT/FCR/SLA-adherence reported together).
Citing zero metrics is non-conforming; citing exactly one is minimum
conformance; citing 2-3 is the performance-axis improvement, not a
must-be.

### Recurring-issue hand-off

Any playbook scenario/escalation entry that identifies a *repeat*
inbound pattern must apply a 5-whys (or equivalent short causal-chain)
check before deciding "hand off to product-discovery" vs. "keep as a
support-side scenario" — per scout-brief's adopt-pattern. Full
SRE-style postmortem tooling (Incident Commander roles, timestamped
timeline reconstruction) is explicitly out of scope per scout-brief's
skip-pattern — disproportionate to this role's producing a
playbook/SLA table, not running a live on-call incident response.

## 3. 채택 근거

- **Impact×urgency priority matrix → adopted.** Directly satisfies
  this role's stated decision, "문의를 어떤 우선순위/SLA로 처리할지" — the
  matrix *is* the priority-decision method, not an incidental add-on.
  Basis: scout-brief must-be #1, sourced from ITIL service-desk
  practice (TOPdesk, InvGate, PagerDuty). Skipping this would leave
  "priority" undefined as a single ungrounded field, exactly the gap
  the survey found in current `directive.sh`.
- **SLA table with escalation-trigger-time column → adopted.**
  Satisfies must-be #2 (SLA timers tied to tier with explicit
  escalation trigger, not just a resolution deadline). Basis: ITIL
  P1–P5 example timelines (TOPdesk/PagerDuty) and COPC CX Standard's
  requirement for objective measures on all customer-impacting
  activities. Ties to `PRODUCES: SLA table` verbatim.
  scout-brief's skip-pattern is why the SLA table norm does not require
  full COPC certification-audit scaffolding (channel-coverage
  breadth is listed as a performance axis, not a must-be) — this role
  is a single-operator/small-team desk (survey + scout-brief
  segment-fit line), not a certified multi-tier contact center.
- **Tiered escalation path (tier/trigger/owner/timeout) → adopted.**
  Satisfies must-be #3. Basis: Atlassian/Rootly/Hyperping playbook and
  escalation-policy convention — "escalation paths should be mapped
  clearly so responders know who to contact and when." Ties to
  `PRODUCES: escalation path` verbatim, and to the `HAND-OFF:` field's
  requirement that a hand-off point be identifiable, not implicit.
- **FCR/CSAT/SLA-adherence as required evidence metric → adopted.**
  Satisfies must-be #4 and performance axis #1. Basis: FCR called "the
  single strongest predictor of CSAT" (Lorikeet, SourceCX); without a
  required metric citation, a delivered playbook has no way to show it
  moved the outcome this role exists to improve.
- **5-whys check before recurring-issue hand-off → adopted, in
  lightweight form only.** Satisfies scout-brief's adopt-pattern
  directly and operationalizes the existing `HAND-OFF: 반복 문의가 제품
  결함이면 → product-discovery` field — currently that field states
  *that* a hand-off should happen but not *how* to decide it is
  warranted. 5-whys gives a minimal, sourced decision procedure
  (Atlassian's postmortem 5-whys writeup) without importing full
  SRE postmortem scaffolding, per scout-brief's skip-pattern and
  segment-fit line (this role is not an on-call org).
- **Full COPC certification / SRE Incident-Commander-style postmortem
  → explicitly not adopted.** Basis: scout-brief's skip-pattern and
  segment-fit line — both are built for a multi-tier contact center or
  on-call production org, disproportionate to a role that produces a
  playbook/SLA table/escalation path document, not an operating
  24/7 desk with shift rosters.

## 4. 플러그인 반영 계획

### `customer-support/hooks/directive.sh`

No change to the 4-field call shape (still `core_role_directive` with
exactly `YOU DECIDE / USE WHEN / PRODUCES / HAND-OFF`) — the norm in
§2 governs the *content* of the deliverables named in `PRODUCES`, not
the directive's own field count. `PRODUCES: support playbook, SLA
table, escalation path` already names all three deliverables this
proposal defines the shape of; no new directive field is needed.

### Record file — new required fields

`docs/issue-<n>/reports/customer-support.md` (the role's record, per
contract v3 s19) must, from phase 2 of this issue onward, always carry:

- Frontmatter: `subject`, `role: customer-support`, `loop_state`
  (existing convention, per docs/issue-5's survey precedent).
- Body must include, whenever the record documents a delivered
  playbook/SLA table/escalation path:
  - A line naming which evidence metric(s) (CSAT/FCR/SLA-adherence)
    the deliverable cites, per §2's required-evidence-metric norm.
  - Confirmation the SLA table has all 6 required columns (§2).
  - Confirmation the escalation path states tier/trigger/owner/timeout
    for every tier (§2).

### Gate — phase-2 proposal

Add a gate (new hook, phase-2 file — not written in this PR) that
blocks `loop_state` from closing on this role's record unless the
record's referenced SLA-table/escalation-path content contains the
required columns/fields from §2 (grep-style structural check, mirroring
how `record-fields-gate.sh` / `stub-check.sh` already do structural
checks elsewhere in this repo's canon, per `docs/issue-5/reports/implementation/survey.md`'s
description of core's gate pattern). Exact script name/location is left
to phase-2 design — flagged as an open question below since this
proposal does not specify gate implementation mechanics.

## Phase-2 write set

- `docs/issue-1/reports/customer-support.md` — new, phase-2 record;
  must carry the fields listed above (evidence metric, SLA-table
  column confirmation, escalation-path field confirmation)
- A support-playbook/SLA-table/escalation-path deliverable file (exact
  path/format not fixed by this proposal — see open question 1) —
  new, structured per §2
- A new gate hook under `customer-support/hooks/` (or a core-canon
  reference to a parameterized core gate, per the issue-2 precedent of
  preferring core references over local copies) — new/edit,
  registered in `customer-support/hooks/hooks.json`
- `customer-support/hooks/directive.sh` — no change (see above)

## Open questions for approver

1. **Deliverable file path/format.** This proposal defines the required
   *structure* of the playbook/SLA table/escalation path (§2) but not
   where in the repo phase 2 should place it (single combined file
   under `customer-support/handbook.md`, or three separate files, or
   embedded in the record itself). Not decided here since the issue
   body does not specify a location convention and no precedent exists
   in this repo.
2. **Gate implementation mechanics.** §4 proposes a structural-check
   gate but does not write it. Per the issue-2 precedent (core-canon
   reference over local copy), should this gate be a new local script,
   or should a phase-2 follow-up first check whether core already
   offers (or should offer) a generic "record contains required
   fields" gate parameterizable per role, avoiding yet another
   role-local script that issue-2/issue-5-style migrations would later
   have to reclaim? Left to the approver/phase-2 design, not decided
   here.

This PR is phase-1 (proposal) only. Phase 2 opens only after an
approvers.md account's PR-review Approve, or the exact-string
`APPROVE issue-1/customer-support` issue comment.
