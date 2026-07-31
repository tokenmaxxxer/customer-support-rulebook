#!/usr/bin/env bash

# customer-support-sla-tier gate: requires an SLA table with all required
# columns before allowing writes to the target surface. Fail-closed.

if [ "${CUSTOMER_SUPPORT_SLA_TIER_GATE_OFF:-}" = "1" ]; then
  exit 0
fi

payload="$(cat)"

if ! echo "$payload" | jq -e . >/dev/null 2>&1; then
  echo "customer-support-sla-tier: fail-closed — could not parse hook payload as JSON" >&2
  exit 2
fi

tool_name=$(echo "$payload" | jq -r '.tool_name // empty')
case "$tool_name" in
  Write|Edit|MultiEdit) ;;
  *) exit 0 ;;
esac

file_path=$(echo "$payload" | jq -r '.tool_input.file_path // empty')
if ! echo "$file_path" | grep -qE '^customer-support/handbook\.md$|^docs/issue-[0-9]+/reports/customer-support\.md$'; then
  exit 0
fi

case "$tool_name" in
  Write)
    content=$(echo "$payload" | jq -r '.tool_input.content')
    ;;
  Edit)
    content=$(echo "$payload" | jq -r '.tool_input.new_string')
    ;;
  MultiEdit)
    content=$(echo "$payload" | jq -r '.tool_input.edits[].new_string')
    ;;
esac

missing=()

echo "$content" | grep -qi 'priority'          || missing+=("sla-table-column:priority")
echo "$content" | grep -qi 'impact'            || missing+=("sla-table-column:impact")
echo "$content" | grep -qi 'urgency'           || missing+=("sla-table-column:urgency")
echo "$content" | grep -qi 'first response'    || missing+=("sla-table-column:first-response")
echo "$content" | grep -qi 'resolution'        || missing+=("sla-table-column:resolution")
echo "$content" | grep -qi 'escalation trigger' || missing+=("sla-table-column:escalation-trigger")

if [ "${#missing[@]}" -gt 0 ]; then
  missing_csv=$(IFS=,; echo "${missing[*]}")
  jq -nc \
    --arg missing "$missing_csv" \
    --arg reason_prefix "customer-support-sla-tier: refused — sla-table write is missing required element(s): " \
    --arg reason_suffix ". Per docs/issue-1/proposals/customer-support.md §2, every phase-2 deliverable/record write must carry: an SLA table with columns Priority tier, Impact rating, Urgency rating, First response time target, Resolution time target, Escalation trigger time, each row derived from the ITIL Impact×Urgency priority matrix." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: ($reason_prefix + $missing + $reason_suffix)}}'
  exit 0
fi

exit 0
