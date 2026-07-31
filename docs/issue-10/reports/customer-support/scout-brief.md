---
subject: issue-10
role: customer-support
---

# Scout brief (issue-10)

Segment: this is infra/enforcement work (a plugin hook-machine), not a
customer-facing product surface — the issue itself names the exemplar
(`implementation-rulebook`'s hook machine) and a second reference
(`pricing-rulebook`'s `methodology-gate.sh`). Per the scout-directive,
a non-product role scouts the best of its own deliverable's kind: here
that is this org's own most mature sibling rulebooks, read directly
from their checked-out worktrees under
`~/.tokenmaxxxer/work/`, not external web search — the exemplars are
named in-repo (issue body) and the survey found the gap is internal
(no enforcement exists here yet), so the field to scout is this org's
own canon precedent, which is exactly what `docs/issue-1/proposals/
customer-support.md`'s adoption precedent (methodology sourced
externally, mechanism sourced internally) implies for a plugin-
machinery issue.

Mode used: **batched-sequential fallback**, stated explicitly per the
scout-directive's fallback-disclosure requirement — each precedent
file was located and read one at a time as the prior read's content
determined the next lookup (survey-first order: the gap found in
`directive.sh`/`hooks.json` drove the next file to check), not fired
as concurrent parallel calls in one turn. 3 stages: (1) locate sibling
rulebook checkouts and the core canon repo, (2) read the two named
exemplars (`pricing/hooks/methodology-gate.sh`,
`core/hooks/record-fields-gate.sh`), (3) read the ordering/test/
directive-richness precedents (`warrant/hooks/state.sh`,
`warrant/hooks/directive.sh`, `docs/handbooks/role-gates-tests.md`,
`docs/handbooks/canon-scripts.md`). Judge point after stage 3: another
round would not change a build decision (the shape of a role-local
methodology gate, its test harness, and directive-richness are all now
directly exemplified) — stopped there, under the 5-stage/3-stage
budget.

## Must-bes (Kano) — what every mature rulebook's enforcement layer has

1. **A role-local methodology gate is a PreToolUse hook targeting this
   role's own write surfaces by regex, fails closed on internal error,
   and has a named kill switch.** Every gate read (`record-fields-
   gate.sh`, `pricing/hooks/methodology-gate.sh`) shares this exact
   shape: `trap __fc EXIT` fail-closed wrapper, `<ROLE>_..._GATE_OFF`
   kill switch, target-path regex scoped to `docs/issue-<n>/...`, deny
   message prefixed `"${role}: refused — ..."`.
2. **Required elements are checked as substring/regex presence on the
   RESOLVED new content** (post-Write/Edit/MultiEdit), not on the tool
   call's raw diff — both gates reconstruct `new_text` from
   `old_string`/`new_string` before checking, and deny outright when
   the resulting content can't be determined (e.g. a Bash write).
3. **Canon scripts are referenced by path against the core plugin
   root, never vendored** (`docs/handbooks/canon-scripts.md`,
   enforced mechanically by `stub-check.sh` against a manifest). A
   role-*specific* gate (this role's SLA/escalation/playbook shape)
   is new content, not a canon copy — `pricing/hooks/methodology-
   gate.sh` is the direct precedent for "role-specific methodology
   logic lives in the role's own `hooks/`, not core's."
4. **A gate test harness runs the gate as a real subprocess** with two
   distinct role/content fixtures (pass case, deny case per missing
   element), per `docs/handbooks/role-gates-tests.md`'s description of
   `run-role-gates-tests.sh`.

## Performance axes (2-3 dimensions mature gates compete on)

1. **Deny-message specificity** — `record-fields-gate.sh` and
   `pricing/hooks/methodology-gate.sh` both name every missing element
   in one deny message, tied back to the source doc (§ number/file) —
   not a generic "methodology check failed."
2. **Ordering enforcement cost vs. need** — `warrant/hooks/state.sh`
   is the only sibling that adds a *SessionStart* state-rebuild step
   (reads `docs/proposals/*.md` frontmatter `status:` field, prints
   open-unit state) because `warrant`'s domain has a genuine
   multi-session-spanning order dependency (proposed -> approved ->
   landed, spanning approval). Gates that don't have that kind of gap
   (record-fields-gate, pricing methodology-gate) skip state-tracking
   entirely and rely on the PreToolUse content-check alone.
3. **Directive richness mechanism** — two distinct shapes exist:
   `core_role_directive`'s fixed 4-field call (all of `customer-
   support`, `pricing`, most rulebooks) vs. `warrant/hooks/
   directive.sh`'s own heredoc-emitting script with no
   `core_role_directive` call at all, used when a role's directive
   content genuinely exceeds what 4 one-line fields can hold.

## Adopt

**Role-local methodology gate, `pricing/hooks/methodology-gate.sh`-
shaped.** Directly satisfies must-be #1/#2/#3: this role's §2 elements
(SLA 6 columns, escalation tier/trigger/owner/timeout, playbook 4
elements/scenario, evidence metric, 5-whys) are exactly the kind of
role-specific structural requirement that gate type checks, and the
`pricing` plugin is the issue's own named reference for this pattern.

## Skip

**`warrant`-style SessionStart state-rebuild script.** The genuine gap
`warrant` closes (a proposal can sit `approved` across session
restarts with no automatic reminder) does not exist for this role: the
handoff contract's own phase-1/phase-2 gate (`approval-gate.sh`/
`board-gate.sh`, core canon, already wired) already blocks phase-2
writes until an Approve lands, and the inner survey->scout-brief->
proposal order within phase 1 is a same-session, single-PR sequence
with no multi-session gap to rebuild state across. Building a second
state-tracking script for an order dependency that is this shallow
would be disproportionate machinery for a 3-file same-PR sequence —
this is the segment-fit judgment call the proposal makes explicit.

## Gap line

Current role state (per survey.md) has **zero** of must-bes #1-#4:
no role-local gate, no canon-referenced-vs-vendored decision made yet
(there is nothing to vendor or reference — the gate doesn't exist),
no test harness, and `directive.sh` is still the plain 4-field call
with no phase/facet depth. All four must-bes are open gaps this
issue's proposal must close; none is already met.

## Re-scout addendum (2026-07-31, approver FEEDBACK on PR #11)

New decisions surfaced mid-build, not covered by the original sweep
above: (1) the Impact×Urgency matrix's source standard must be named
explicitly rather than inherited by reference from
`docs/issue-1/proposals/customer-support.md`; (2) whether KCS
(Knowledge-Centered Service) should be adopted as the canonical
methodology for this role's handbook-production output; (3) whether
5-whys reliance should be reconsidered against wider problem-management
practice. One micro-round, web search (parallel, this session), judge
point after one round — sufficient, no further round needed:

1. **ITIL, named explicitly.** The Impact×Urgency priority matrix is
   ITIL's service-desk incident-prioritization method (impact × urgency
   → priority), documented across ITIL-aligned ITSM vendor guides
   (ManageEngine, InvGate, Freshworks — see Sources). `docs/issue-1/
   proposals/customer-support.md` §3 already names "ITIL impact×urgency
   matrix" as the basis; this issue's own proposal (§2.1) previously
   only said "an Impact×Urgency pair" with no standard name attached —
   gap closed by citing ITIL directly in this document, not only by
   reference to issue-1.

2. **KCS (Knowledge-Centered Service) — must-be for handbook-production
   roles.** KCS is the Consortium for Service Innovation's methodology
   (KCS® registered service mark) for producing and maintaining support
   knowledge content as a by-product of the support workflow itself.
   Its **Content Standard** defines the canonical article shape:
   **Issue** (the question/problem as the customer/agent experiences
   it) → **Environment** (context that scopes when it applies) →
   **Resolution** (the actual fix/answer) → **Cause** (root cause, when
   known) → **Metadata** (reuse/lifecycle fields — e.g. a article
   maturity/state field). This is a direct structural fit for
   `customer-support`'s deliverable: the same shape as a playbook
   scenario entry, formalized under a named external standard instead
   of an ad hoc "trigger/decision-criteria/script/escalation-condition"
   list invented without citation. Segment fit: KCS explicitly targets
   any support-knowledge-producing function regardless of org size —
   the "solve loop" (capture knowledge at point of use, reuse before
   research, evolve content collaboratively) applies as directly to a
   single-operator desk as to a large contact center, unlike COPC
   certification scaffolding (already skipped, per original brief, as
   disproportionate to org size).

3. **5-whys — reconsidered, not dropped.** ITIL problem-management
   literature treats 5-whys as one of several root-cause-analysis
   techniques (alongside Ishikawa/fishbone and Kepner-Tregoe), and is
   explicit that 5-whys "is best used on simple to moderately difficult
   problems" and "tends to limit the analysis to just one avenue of
   root cause identification" for problems with multiple root causes —
   it is not a universal RCA default even within ITIL's own practice.
   This does not overturn the original adopt-pattern (5-whys is still
   the right minimal tool for *this* role's segment — a single-operator
   support desk deciding "hand off or not," not running formal problem
   management with a KEDB), but the proposal's §2.5/§3 must now state
   this scope bound explicitly rather than cite 5-whys as if it were
   the field's uncontested default: 5-whys stays the required minimum
   check, but a recurring pattern that resists a clean single-chain
   5-whys answer (i.e. the 5 answers don't converge on one cause) must
   route to product-discovery on that basis alone, rather than forcing
   a strained single-cause 5-whys narrative — the gate can only check
   presence of 5 question-lines (shape, not correctness, per open
   question 2, unchanged), so this scope bound is directive-level
   judgment, not a new gate check.

Mode: parallel WebSearch (2 queries, one turn) — genuine fan-out, not
serialized. Stage count: 1 (sufficient; judged at JUDGE POINT 1 that a
second round would not change the build decision — KCS's Content
Standard and the ITIL RCA literature's own scope caveat both directly
resolved the three open decisions).

## Sources

- `customer-support/hooks/directive.sh`,
  `customer-support/hooks/hooks.json`,
  `customer-support/handbook.md` (this repo, current tree)
- `docs/issue-1/proposals/customer-support.md`,
  `docs/issue-1/reports/customer-support/scout-brief.md` (this repo)
- `~/.tokenmaxxxer/work/pricing-rulebook-issue-1-pricing/pricing/hooks/methodology-gate.sh`
- `~/.tokenmaxxxer/work/tokenmaxxxer-core-issue-69-implementation/core/hooks/record-fields-gate.sh`
- `~/.tokenmaxxxer/work/tokenmaxxxer-core-issue-69-implementation/warrant/hooks/state.sh`
- `~/.tokenmaxxxer/work/tokenmaxxxer-core-issue-69-implementation/warrant/hooks/directive.sh`
- `~/.tokenmaxxxer/work/tokenmaxxxer-core-issue-69-implementation/docs/handbooks/role-gates-tests.md`
- `~/.tokenmaxxxer/work/tokenmaxxxer-core-issue-69-implementation/docs/handbooks/canon-scripts.md`
- `~/.tokenmaxxxer/work/tokenmaxxxer-core-issue-69-implementation/core/hooks/lib/role-directive.sh`
- https://library.serviceinnovation.org/KCS/KCS_v6/KCS_Principles_and_Core_Concepts
- https://library.serviceinnovation.org/KCS/KCS_v6/KCS_v6_Practices_Guide/020
- https://www.teamdynamix.com/blog/knowledge-centered-service-101-understanding-the-basics-of-kcs/
- https://en.wikipedia.org/wiki/Knowledge-centered_support
- https://www.manageengine.com/products/service-desk/itsm/problem-management-techniques.html
- https://blog.invgate.com/4-problem-management-root-cause-analysis-techniques-explained
- https://kepner-tregoe.com/blogs/how-5-whys-and-fishbone-diagrams-relate-to-kt-problem-analysis/
