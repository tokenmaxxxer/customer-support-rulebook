#!/usr/bin/env bash
set -u

if [ "${CUSTOMER_SUPPORT_EVIDENCE_METRIC_GATE_OFF:-}" = "1" ]; then
  exit 0
fi

payload="$(cat)"

if ! echo "$payload" | jq -e . >/dev/null 2>&1; then
  echo "customer-support-evidence-metric: fail-closed — malformed JSON payload on stdin." >&2
  exit 2
fi

tool_name=$(echo "$payload" | jq -r '.tool_name // empty')
case "$tool_name" in
  Write|Edit|MultiEdit) ;;
  *) exit 0 ;;
esac

file_path=$(echo "$payload" | jq -r '.tool_input.file_path // empty')

if ! echo "$file_path" | grep -Eq '^customer-support/handbook\.md$|^docs/issue-[0-9]+/reports/customer-support\.md$'; then
  exit 0
fi

case "$tool_name" in
  Write)
    content=$(echo "$payload" | jq -r '.tool_input.content // empty')
    ;;
  Edit)
    content=$(echo "$payload" | jq -r '.tool_input.new_string // empty')
    ;;
  MultiEdit)
    content=$(echo "$payload" | jq -r '[.tool_input.edits[].new_string] | join("\n")')
    ;;
esac

content_lc=$(echo "$content" | tr '[:upper:]' '[:lower:]')

missing=()
if ! echo "$content_lc" | grep -Eq 'csat|fcr|first contact resolution|sla-adherence|sla adherence'; then
  missing+=("evidence-metric")
fi

if [ "${#missing[@]}" -gt 0 ]; then
  missing_joined=$(IFS=', '; echo "${missing[*]}")
  reason="customer-support-evidence-metric: refused — write is missing required element(s): ${missing_joined}. Per docs/issue-1/proposals/customer-support.md §2, every phase-2 deliverable/record write must carry: at least one evidence metric (CSAT, FCR/First Contact Resolution, or SLA-adherence) cited."
  python3 - "$reason" <<'PYEOF'
import json, sys
reason = sys.argv[1]
out = {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": reason}}
print(json.dumps(out))
PYEOF
  exit 0
fi

exit 0
