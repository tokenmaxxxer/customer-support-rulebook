# Scout brief (issue-1, role: customer-support)

Stages run: 3 (survey → sweep of 3 parallel angles → 1 deepening pass on
metrics/RCA). Saturation reached at stage 3: every additional source
repeated the same must-be structure (impact×urgency priority, tiered
escalation, RCA on recurring issues) without adding a new required
component, so the sweep stopped under the 5-stage/3-min cap.

## Must-bes (Kano — table stakes, absence causes rejection)

1. **Priority = impact × urgency matrix**, not a single "priority" field
   guessed ad hoc. ITIL service-desk practice derives priority from an
   impact/urgency grid (P1–P5), not from either axis alone.
2. **SLA timers tied to priority tier, with an explicit escalation
   trigger time**, not just a resolution deadline. E.g. P1: response in
   15 min, escalate if unresolved by 30 min.
3. **Escalation path with named tiers/owners and timeout**, not a bare
   "escalate to manager" line — playbook practice requires explicit
   roles (who is contacted), thresholds (when), and ownership.
4. **First-contact-resolution as the primary quality signal**, not
   ticket-closed-count. FCR is called the single strongest predictor of
   CSAT industry-wide.

## Performance axes (more = incrementally better, not pass/fail)

1. **CSAT / FCR / SLA-adherence reported together**, not any single
   metric alone — richer evidence, diminishing returns past 2-3 metrics.
2. **RCA depth on recurring/repeat tickets** (5-whys or equivalent chain
   reasoning) — more rigor helps distinguish a one-off from a systemic
   defect that should hand off to product-discovery, but full formal
   postmortem tooling (SRE-grade blameless postmortem docs) is more than
   this role needs.
3. **Channel coverage breadth** (phone/chat/email/social) per COPC CX
   scope — more channels documented in the playbook is better, but not
   a must-be for a text-based support flow.

## One pattern to adopt / one to skip

- **Adopt: impact×urgency priority matrix + tiered SLA/escalation
  table** (ITIL incident management, COPC CX Standard). Directly matches
  this role's stated decision: "문의를 어떤 우선순위/SLA로 처리할지." This
  is the load-bearing methodology for both the SLA table and escalation
  path deliverables.
- **Skip: full SRE-style blameless incident postmortem apparatus**
  (timestamped timeline reconstruction, named Incident Commander/Scribe
  roles, formal postmortem doc for every incident). Recurring-ticket RCA
  only needs the 5-whys causal-chain step to decide "product defect →
  hand off to product-discovery"; the heavier postmortem scaffolding is
  built for live production incidents with an on-call rotation, which
  this role does not run.

## Segment-fit line

This repo's customer-support role is a single-operator/small-team
support desk deciding priority/SLA/escalation for a product's inbound
support queue — not a multi-tier BPO contact center (COPC's certified
scope) or an SRE on-call org (Atlassian/PagerDuty postmortem scope).
Adopt the priority-matrix/SLA-table/escalation-tier *structure* from
those larger domains; skip their organizational scaffolding (shift
rosters, formal certification audits, Incident Commander rotations) as
disproportionate to this role's producing a playbook/SLA
table/escalation path, not running a 24/7 operation.

## GAP LINE

Current repo state (`customer-support/hooks/directive.sh`) already
states the *decision* ("어떤 우선순위/SLA로 처리할지") and the *deliverable
names* (support playbook, SLA table, escalation path) but defines none
of their required internal structure — no priority-matrix method, no
required SLA-table columns, no required escalation-tier fields, no
required evidence metric. Missing entirely: any reference to
impact×urgency classification, RCA method for recurring-issue hand-off
to product-discovery, or which metric (CSAT/FCR/SLA-adherence)
phase-2 output must cite as evidence. This proposal fills that gap.

## Sources

- [TOPdesk — ITIL Incident Priority Matrix](https://www.topdesk.com/en/blog/incident-priority-matrix/)
- [InvGate — ITIL Priority Matrix: How to Build And Use It](https://blog.invgate.com/itil-priority-matrix)
- [PagerDuty — Using the Incident Priority Matrix](https://www.pagerduty.com/resources/digital-operations/learn/incident-priority-matrix/)
- [COPC Inc. — COPC Customer Experience (CX) Standard](https://www.copc.com/copc-standards/cx-standard/)
- [COPC CX Standard for Customer Operations PDF](https://cx.copc.com/hubfs/PDF/COPC_2021_CX_Standard_for_Customer_Operations_Release_7.0.pdf)
- [Atlassian — How to create an incident response playbook](https://www.atlassian.com/incident-management/incident-response/how-to-create-an-incident-response-playbook)
- [Rootly — Incident Response Playbooks](https://rootly.com/incident-response/playbooks)
- [Hyperping — Escalation Policy Guide + Free Templates](https://hyperping.com/blog/escalation-policies-guide)
- [Lorikeet — Customer Service Metrics That Actually Matter](https://www.lorikeetcx.ai/articles/customer-service-metrics)
- [SourceCX — CX Metrics That Matter: CSAT, NPS, CES, FCR](https://sourcecx.com/cx-metrics-csat-nps-ces-first-contact-resolution/)
- [Wikipedia — First call resolution](https://en.wikipedia.org/wiki/First_call_resolution)
- [Atlassian — Postmortems: Enhance Incident Management Processes](https://www.atlassian.com/incident-management/handbook/postmortems)
- [Atlassian — The power of 5 Whys: analysis and defense](https://www.atlassian.com/incident-management/postmortem/5-whys)
- [KPI Fire — 5 Whys Root Cause Analysis: A Simple Guide](https://www.kpifire.com/blog/5-whys-root-cause-analysis/)

Assumption (unsourced): this repo's customer-support role operates as a
single-operator/small-team desk rather than a multi-tier contact center
— inferred from the role's plugin.json scope, not from an external
source; stated explicitly here rather than presented as researched fact.
