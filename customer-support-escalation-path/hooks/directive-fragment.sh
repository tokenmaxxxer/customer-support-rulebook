#!/usr/bin/env bash
cat <<'EOF'
## Escalation-path discipline (customer-support-escalation-path plugin)

PROHIBITED: a bare "escalate to manager if unresolved" line with no named
owner and no timeout. Every escalation tier must state a trigger condition,
a named owner (a role/title, e.g. "Support Team Lead" or "Duty Manager" —
not a generic "the team"), and a timeout.

A generic owner value like "the team" with no role/title is non-compliant
even if the gate's presence check for the literal word "owner" passes. The
gate (hooks/gate.sh) can only check that the word "owner" appears somewhere
in the content — it has no way to judge whether the owner value named is
actually a role/title or just a vague placeholder like "the team" or
"someone". That semantic genericness check is the judgment layer's job, not
the gate's: apply it yourself when writing or reviewing escalation-path
sections, and refuse to accept "the team" as a named owner even when the
gate stays silent.

Norm source: docs/issue-1/proposals/customer-support.md §2/§3.
EOF
