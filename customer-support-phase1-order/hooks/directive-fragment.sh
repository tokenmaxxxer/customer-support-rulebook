#!/usr/bin/env bash
cat <<'EOF'
## Phase-1 proposal order and citation judgment (customer-support-phase1-order)

Phase-1 customer-support proposal work follows a strict 3-artifact order, within the
same PR and the same working session:

  1. survey.md       (docs/issue-<n>/reports/customer-support/survey.md)
  2. scout-brief.md  (docs/issue-<n>/reports/customer-support/scout-brief.md)
  3. proposal.md     (docs/issue-<n>/proposals/customer-support.md)

Do not begin drafting the proposal before the survey and scout-brief for the same
issue already exist on disk. This is not a formality: the proposal's structural
claims (SLA commitments, escalation paths, playbook references, evidence metrics,
5-whys scope) are supposed to be *derived from* what the survey and scout-brief
already established — writing the proposal first inverts the dependency and invites
claims that sound structural but were never actually grounded in field evidence.

No uncited structural claim: every claim in the proposal that touches SLA,
escalation, playbook, evidence metrics, or 5-whys scope must be traceable to a
specific scout-brief finding (cited as `scout-brief.md`, ideally with a section/line
pointer) or an external primary source (an http(s) URL).

This directive is a level above what the gate hook can mechanically check. The gate
only verifies that a citation marker (a `scout-brief.md` mention or an http(s) URL)
exists somewhere in the write payload — it cannot verify that the citation actually
backs the specific claim it sits near. Judgment is required here: a citation line
that points at a scout-brief section which does not, on inspection, actually support
the claim it is attached to satisfies the gate's regex but violates this directive.
Before writing or approving a proposal edit, verify each citation is doing real
argumentative work, not just present as decoration to pass the syntactic check.

Authority: docs/issue-1/proposals/customer-support.md §1 (phase-1 artifact order and
citation discipline for customer-support methodology proposals).
EOF
