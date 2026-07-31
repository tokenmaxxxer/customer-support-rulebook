#!/usr/bin/env bash

# customer-support-escalation-path gate: requires that any "escalation path"
# section state a trigger, a named owner, and a timeout. Fail-closed.

if [ "${CUSTOMER_SUPPORT_ESCALATION_PATH_GATE_OFF:-}" = "1" ]; then
  exit 0
fi

payload="$(cat)"

if ! echo "$payload" | jq -e . >/dev/null 2>&1; then
  echo "customer-support-escalation-path: fail-closed — could not parse hook payload as JSON" >&2
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

# Only fire when an "escalation path" section marker is present. Otherwise
# this write has no applicable content — pass without checking.
if ! echo "$content" | grep -qi 'escalation path'; then
  exit 0
fi

missing=()

echo "$content" | grep -qi 'trigger' || missing+=("escalation-field:trigger")
echo "$content" | grep -qi 'owner'   || missing+=("escalation-field:owner")
echo "$content" | grep -qi 'timeout' || missing+=("escalation-field:timeout")

if [ "${#missing[@]}" -gt 0 ]; then
  missing_csv=$(IFS=,; echo "${missing[*]}")
  jq -n \
    --arg missing "$missing_csv" \
    --arg reason_prefix "customer-support-escalation-path: refused — escalation-field write is missing required element(s): " \
    --arg reason_suffix ". Per docs/issue-1/proposals/customer-support.md §2, every phase-2 deliverable/record write must carry: an escalation path where every tier row/block states a trigger condition, a named owner (a role/title, not a generic 'the team'), and a timeout." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: ($reason_prefix + $missing + $reason_suffix)}}'
  exit 0
fi

exit 0
