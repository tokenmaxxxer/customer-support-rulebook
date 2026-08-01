#!/usr/bin/env bash
cat <<'EOF'
## Evidence-Metric Citation (judgment level)

PROHIBITED: citing a metric by name with no sentence connecting it to what the
deliverable actually does to move that metric. Writing "CSAT" once with no
explanation of mechanism is a shape-pass that fails this directive even
though it satisfies the gate.

Per docs/issue-1/proposals/customer-support.md §2/§3, every phase-2
deliverable or record write must cite at least one evidence metric (CSAT,
FCR/First Contact Resolution, or SLA-adherence) AND explain, in a real
sentence, how the deliverable's content is expected to move that metric.

The mechanical gate (hooks/evidence-metric-gate.sh) can only check for the presence of a
metric name/synonym in the written text — it cannot verify that a causal
sentence connects the deliverable to the metric. That verification is this
directive's job: before finalizing a write to a target file, confirm the
metric is not just named but tied to a concrete causal claim about the
deliverable's effect on it.
EOF
