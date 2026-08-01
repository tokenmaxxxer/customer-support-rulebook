#!/usr/bin/env bash
cat <<'EOF'
## SLA-tier table discipline (customer-support-sla-tier plugin)

Every SLA-tier table row must be derived from an ITIL Impact x Urgency priority
matrix pair — this is the ITIL service-desk incident-prioritization convention:
you look up a given (Impact rating, Urgency rating) pair in the matrix and the
matrix cell yields the Priority tier. Do not assert a tier label (e.g.
"P1"/"Critical") that has no impact/urgency pair actually behind it — a tier
value must be traceable back to the ITIL matrix lookup that produced it, not
just written down because it "feels" high priority.

Norm source: docs/issue-1/proposals/customer-support.md §2/§3.

Enforcement level: this is a judgment-level directive, not something the
gate's regex checks can verify. The gate script (hooks/sla-tier-gate.sh) only checks
that an SLA table exists with the required column headers (Priority, Impact,
Urgency, First response, Resolution, Escalation trigger). A table that has
all the right column headers but whose Priority values are not actually
traceable to an Impact x Urgency pair passes the gate mechanically while
still violating this directive. Apply this judgment yourself when writing or
reviewing SLA-tier tables.
EOF
