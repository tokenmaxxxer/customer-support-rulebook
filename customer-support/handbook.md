# Customer Support Handbook

Single combined deliverable for `customer-support`'s phase-2 output:
priority/SLA table, escalation path, and support playbook. Structure
follows `docs/issue-1/proposals/customer-support.md` §2.

## 1. Priority tiers and SLA

### Tier derivation

Priority tier is derived from **Impact × Urgency** (ITIL impact/urgency
matrix), not asserted directly:

- High impact + High urgency → **P1**
- High impact + Medium urgency, or Medium impact + High urgency → **P2**
- Medium impact + Medium urgency, or Low impact + High urgency → **P3**
- Low impact + Low/Medium urgency → **P4**

### SLA table

| Priority tier | Impact rating | Urgency rating | First response time target | Resolution time target | Escalation trigger time |
|---|---|---|---|---|---|
| P1 | High | High | 15 min | 4 h | 1 h unresolved |
| P2 | High | Medium | 30 min | 8 h | 2 h unresolved |
| P3 | Medium | Medium | 4 h | 24 h | 8 h unresolved |
| P4 | Low | Low/Medium | 24 h | 72 h | 24 h unresolved |

## 2. Escalation path

| Tier | Trigger condition | Owner | Timeout |
|---|---|---|---|
| L1 | New ticket intake / any inbound not yet triaged | Support Agent | Must classify against SLA table and respond within tier's first-response target |
| L2 | L1 cannot resolve within tier's escalation trigger time, or ticket is P1/P2 at intake | Support Lead | Must resolve or reassign within remaining resolution-time budget for the tier, else escalate to L3 |
| L3 | L2 identifies a product defect, outage, or cannot resolve within remaining SLA budget | Engineering On-call | Must acknowledge within 15 min of L2 hand-off and drive to resolution or mitigation |

## 3. Support playbook

### Scenario A — Account/login lockout (P2 pattern)

- **Trigger/scenario**: Customer cannot log in; account shows locked/suspended.
- **Decision criteria**: High impact (blocks all product use) but usually Medium urgency (single user, workaround via password reset exists) → **P2** per the impact/urgency matrix above.
- **Script/response template**: "I'm sorry for the trouble logging in. I've sent a secure password reset link to your registered email — it should arrive within a few minutes. Once you're back in, let us know if the issue persists and we'll investigate further."
- **Escalation condition**: If reset does not restore access within 30 minutes, escalate to **L2 (Support Lead)** per the escalation path; if root cause is a platform-wide auth outage, **L2 escalates to L3 (Engineering On-call)** immediately.

### Scenario B — Billing discrepancy (P3 pattern)

- **Trigger/scenario**: Customer reports being charged an incorrect amount.
- **Decision criteria**: Medium impact (financial, but not service-blocking) and Medium urgency (no immediate outage) → **P3** per the impact/urgency matrix above.
- **Script/response template**: "Thanks for flagging this — I can see the charge you're referring to. I'm reviewing your billing history now and will confirm whether this was billed correctly or issue a correction within one business day."
- **Escalation condition**: If the discrepancy cannot be explained/corrected by L1 within the P3 resolution window, escalate to **L2 (Support Lead)** per the escalation path for billing-system review.

### Scenario C — Service outage / critical bug report (P1 pattern)

- **Trigger/scenario**: Multiple customers report the core product is unavailable or a critical feature is broken.
- **Decision criteria**: High impact (service-wide) and High urgency (active, spreading) → **P1** per the impact/urgency matrix above.
- **Script/response template**: "We're aware of an issue affecting [feature/service] and are actively investigating. We'll update you within [first-response target] with status, and will keep this ticket updated until resolved."
- **Escalation condition**: P1 tickets escalate immediately to **L2 (Support Lead)** on intake, and **L2 escalates to L3 (Engineering On-call)** without waiting for the full escalation-trigger window, per the escalation path.

### Scenario D — Recurring "feature X is confusing" reports (repeat inbound pattern)

- **Trigger/scenario**: The same complaint about a specific feature/flow recurs across multiple, unrelated customers over a short window.
- **Decision criteria**: Typically Low/Medium impact per individual ticket (workaround exists) but the *recurrence* itself is the signal → classify individual tickets P3/P4 per the matrix, but flag the pattern for hand-off review (see §5).
- **Script/response template**: "Thanks for the feedback — you're not the only one who's found this confusing. I'll walk you through it now: [steps], and I'm also flagging this pattern internally so we can improve it."
- **Escalation condition**: Individual tickets stay support-side unless the 5-whys check in §5 concludes the root cause is a product defect, in which case hand off to product-discovery rather than escalating up the L1→L3 path.

## 4. Evidence metric

This SLA table and playbook are designed to move **FCR (First Contact
Resolution)** and **CSAT**, per scout-brief must-be #4
(`docs/issue-1/reports/customer-support/scout-brief.md`), which
identifies FCR as the strongest predictor of CSAT. Response scripts
above are written to resolve the reported issue in the first contact
wherever possible, and tiered SLA targets exist so that when first-contact
resolution isn't possible, time-to-resolution stays within the customer's
expectation, protecting CSAT.

## 5. Recurring-issue hand-off (5-whys check)

Any playbook scenario that identifies a **repeat inbound pattern**
(e.g. Scenario D above) must run a lightweight 5-whys check before
deciding whether to hand off to product-discovery or keep it as a
support-side scenario. This is intentionally limited to five questions
— it is not full SRE-style postmortem tooling (no incident commander
roles, no timestamped timeline reconstruction):

1. Why are customers hitting this? (What are they trying to do?)
2. Why doesn't the current product flow/documentation prevent the confusion or error?
3. Why hasn't this been fixed already — is it a known limitation, a regression, or new?
4. Why would a support-side workaround (macro, doc update, script) not be sufficient going forward?
5. Why would fixing this require product/engineering change rather than a support process change?

If the answer to (5) is "yes, it requires a product change," hand off
to product-discovery. Otherwise, keep it as a support-side scenario
and add/update a playbook entry and response script instead.
