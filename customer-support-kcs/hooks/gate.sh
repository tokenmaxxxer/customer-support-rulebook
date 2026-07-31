#!/usr/bin/env bash

if [ "${CUSTOMER_SUPPORT_KCS_GATE_OFF}" = "1" ]; then
  exit 0
fi

payload="$(cat)"

if ! echo "$payload" | jq -e . >/dev/null 2>&1; then
  echo "customer-support-kcs: refused — malformed JSON payload, failing closed." >&2
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

if ! printf '%s' "$lower" | grep -qi 'issue'; then
  missing+=("kcs-element:issue")
fi

if ! printf '%s' "$lower" | grep -qi 'environment'; then
  missing+=("kcs-element:environment")
fi

if ! printf '%s' "$lower" | grep -qi 'resolution'; then
  missing+=("kcs-element:resolution")
fi

if ! printf '%s' "$lower" | grep -qi 'cause'; then
  missing+=("kcs-element:cause")
fi

if ! printf '%s' "$lower" | grep -qiE 'metadata|state|maturity'; then
  missing+=("kcs-element:metadata")
fi

if [ "${#missing[@]}" -gt 0 ]; then
  missing_joined=$(IFS=,; echo "${missing[*]}")
  python3 -c '
import json, sys
missing = sys.argv[1]
reason = (
    "customer-support-kcs: refused — kcs write is missing required element(s): "
    + missing
    + ". Per docs/issue-1/proposals/customer-support.md §2, every phase-2 deliverable/record write must carry: "
    + "for each handbook article/scenario entry: KCS Content Standard fields Issue, Environment, Resolution, Cause, and Metadata (a reuse/lifecycle state field)."
)
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": reason}}))
' "$missing_joined"
  exit 0
fi

exit 0
