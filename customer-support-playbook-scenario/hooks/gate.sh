#!/usr/bin/env bash

if [ "${CUSTOMER_SUPPORT_PLAYBOOK_SCENARIO_GATE_OFF}" = "1" ]; then
  exit 0
fi

payload="$(cat)"

if ! echo "$payload" | jq -e . >/dev/null 2>&1; then
  echo "customer-support-playbook-scenario: refused — malformed JSON payload, failing closed." >&2
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
    content=$(echo "$payload" | jq -r '.tool_input.content // empty')
    ;;
  Edit)
    content=$(echo "$payload" | jq -r '.tool_input.new_string // empty')
    ;;
  MultiEdit)
    content=$(echo "$payload" | jq -r '[.tool_input.edits[].new_string] | join("\n")')
    ;;
esac

lower=$(printf '%s' "$content" | tr '[:upper:]' '[:lower:]')

has_marker=0
if printf '%s' "$content" | grep -qiE '^#+ .*scenario'; then
  has_marker=1
elif printf '%s' "$lower" | grep -qi 'scenario'; then
  has_marker=1
elif printf '%s' "$lower" | grep -qi 'playbook'; then
  has_marker=1
fi

if [ "$has_marker" -ne 1 ]; then
  exit 0
fi

missing=()

if ! printf '%s' "$lower" | grep -qiE 'trigger|scenario'; then
  missing+=("playbook-element:trigger-or-scenario")
fi

if ! printf '%s' "$lower" | grep -qi 'decision criteria'; then
  missing+=("playbook-element:decision-criteria")
fi

if ! printf '%s' "$lower" | grep -qiE 'script|response template|response'; then
  missing+=("playbook-element:script-or-response")
fi

if ! printf '%s' "$lower" | grep -qi 'escalation condition'; then
  missing+=("playbook-element:escalation-condition")
fi

if [ "${#missing[@]}" -gt 0 ]; then
  missing_joined=$(IFS=,; echo "${missing[*]}")
  python3 -c '
import json, sys
missing = sys.argv[1]
reason = (
    "customer-support-playbook-scenario: refused — playbook-scenario write is missing required element(s): "
    + missing
    + ". Per docs/issue-1/proposals/customer-support.md §2, every phase-2 deliverable/record write must carry: "
    + "for each playbook scenario: a trigger/scenario description, decision criteria, a script/response template, and an escalation condition."
)
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": reason}}))
' "$missing_joined"
  exit 0
fi

exit 0
