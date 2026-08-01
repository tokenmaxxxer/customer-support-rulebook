#!/usr/bin/env bash
cat <<'EOF'
## customer-support-five-whys: recurring-pattern hand-off directive

PROHIBITED: writing "hand off to product-discovery" for a flagged
repeat/recurring inbound pattern entry with no 5-whys answers preceding
it in the same entry. Any scenario/report entry that flags a repeat or
recurring inbound pattern must carry a 5-whys check — five distinct
question-shaped lines — in the same section, before any hand-off
decision is recorded.

NEW rule (this revision, §2.5): a recurring pattern whose 5-whys
answers do not converge on one causal chain — the "why" lines branch
into multiple unrelated causes rather than one chain — must route to
product-discovery on that basis alone. Forcing a single strained
5-whys narrative onto a multi-cause pattern is itself a violation of
the technique's documented limits (ITIL problem-management treats
5-whys as fitting "simple to moderately difficult" problems, per
Kepner-Tregoe/InvGate technique comparisons), not a compliant use of
it.

This role's segment — a single-operator support desk deciding
hand-off, not formal KEDB problem management — is exactly the case the
technique fits. That is why 5-whys stays adopted here, but with this
explicit scope bound rather than as ITIL's uncontested default.

The mechanical gate (hooks/five-whys-gate.sh) can only check shape — the
"5-whys" label plus a count of >=5 question-shaped lines. It cannot verify
that the five questions match checklists/5-whys-recurring.md's specific
causal-chain questions, nor that they satisfy this fragment's own §2.5
convergence rule above. That verification is the judgment layer's job:
apply the checklist and the §2.5 convergence bound yourself even when the
gate stays silent.

Checklist: checklists/5-whys-recurring.md
Reference: docs/issue-1/proposals/customer-support.md §2/§3
EOF
