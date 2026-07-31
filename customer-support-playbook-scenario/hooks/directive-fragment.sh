#!/usr/bin/env bash
cat <<'EOF'
PROHIBITED — a script with no escalation condition, or an escalation condition naming no tier defined by the escalation-path plugin's output (i.e. the escalation condition must reference an actual tier like L1/L2/L3 from the escalation path, not a vague "escalate if needed"). This plugin's gate only checks presence of the four labeled elements (trigger/scenario, decision criteria, script/response, escalation condition); the directive is the judgment layer that catches a present-but-empty or non-referential escalation condition. Cite docs/issue-1/proposals/customer-support.md §2/§3.
EOF
