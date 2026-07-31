#!/usr/bin/env bash
set -u

if [[ "${CUSTOMER_SUPPORT_PHASE1_ORDER_GATE_OFF:-}" == "1" ]]; then
  exit 0
fi

payload="$(cat)"

if ! echo "$payload" | jq -e . >/dev/null 2>&1; then
  echo "customer-support-phase1-order: fail-closed — malformed JSON payload on stdin." >&2
  exit 2
fi

tool_name=$(echo "$payload" | jq -r '.tool_name // empty')
case "$tool_name" in
  Write|Edit|MultiEdit) ;;
  *) exit 0 ;;
esac

file_path=$(echo "$payload" | jq -r '.tool_input.file_path // empty')

if [[ ! "$file_path" =~ ^docs/issue-([0-9]+)/proposals/customer-support\.md$ ]]; then
  exit 0
fi

n="${BASH_REMATCH[1]}"

root="${CLAUDE_PROJECT_DIR:-.}"
survey_path="${root}/docs/issue-${n}/reports/customer-support/survey.md"
scout_path="${root}/docs/issue-${n}/reports/customer-support/scout-brief.md"

missing=()

[[ -f "$survey_path" ]] || missing+=("artifact-order:survey")
[[ -f "$scout_path" ]] || missing+=("artifact-order:scout-brief")

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

check_facet() {
  local keyword="$1" facet="$2"
  if echo "$content" | grep -qiE "$keyword"; then
    if ! echo "$content" | grep -qiE '(scout-brief\.md|https?://)'; then
      missing+=("uncited-claim:${facet}")
    fi
  fi
}

check_facet "sla" "sla"
check_facet "escalation" "escalation"
check_facet "playbook" "playbook"
check_facet "evidence metric" "evidence-metric"
check_facet "(5-whys|five whys)" "five-whys"

if [[ ${#missing[@]} -gt 0 ]]; then
  IFS=', '
  missing_str="${missing[*]}"
  unset IFS
  python3 -c "
import json
missing_str = '''${missing_str}'''
out = {
  'hookSpecificOutput': {
    'hookEventName': 'PreToolUse',
    'permissionDecision': 'deny',
    'permissionDecisionReason': (
      'customer-support-phase1-order: refused — proposal write is missing required '
      'element(s): ' + missing_str + '. Per docs/issue-1/proposals/customer-support.md '
      '§1, phase-1 proposals must follow the survey→scout-brief→proposal order '
      'and cite every structural claim to a scout-brief source.'
    )
  }
}
print(json.dumps(out))
"
  exit 0
fi

exit 0
