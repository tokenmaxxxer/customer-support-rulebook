#!/usr/bin/env bash
# customer-support-five-whys gate: enforces 5-whys presence for
# repeat/recurring-pattern entries in handbook/report writes.

if [ "${CUSTOMER_SUPPORT_FIVE_WHYS_GATE_OFF:-}" = "1" ]; then
  exit 0
fi

payload="$(cat)"

if ! echo "$payload" | jq -e . >/dev/null 2>&1; then
  echo "customer-support-five-whys: gate failed closed — could not parse hook payload as JSON." >&2
  exit 2
fi

tool_name=$(echo "$payload" | jq -r '.tool_name // empty')
case "$tool_name" in
  Write|Edit|MultiEdit) ;;
  *) exit 0 ;;
esac

file_path=$(echo "$payload" | jq -r '.tool_input.file_path // empty')
if ! echo "$file_path" | grep -E '^customer-support/handbook\.md$|^docs/issue-[0-9]+/reports/customer-support\.md$' >/dev/null 2>&1; then
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
    content=$(echo "$payload" | jq -r '[.tool_input.edits[]?.new_string] | join("\n")')
    ;;
esac

missing=()

lower_content=$(echo "$content" | tr '[:upper:]' '[:lower:]')

if echo "$lower_content" | grep -qE 'repeat|recurring'; then
  has_label=0
  if echo "$lower_content" | grep -qE '5-whys|five whys'; then
    has_label=1
  fi

  question_count=$(echo "$content" | grep -cE '\?[[:space:]]*$')

  if [ "$has_label" -eq 0 ] || [ "$question_count" -lt 5 ]; then
    missing+=("5-whys-check")
  fi
fi

if [ "${#missing[@]}" -gt 0 ]; then
  missing_joined=$(IFS=,; echo "${missing[*]}")
  python3 - "$missing_joined" <<'PYEOF'
import json
import sys

missing_joined = sys.argv[1]
reason = (
    "customer-support-five-whys: refused — recurring-pattern write is missing "
    "required element(s): " + missing_joined + ". Per docs/issue-1/proposals/"
    "customer-support.md §2, every phase-2 deliverable/record write must "
    "carry: when content flags a repeat/recurring inbound pattern: a 5-whys "
    "check with at least 5 distinct question-shaped lines, present in the same "
    "section, before any hand-off decision."
)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }
}))
PYEOF
  exit 0
fi

exit 0
