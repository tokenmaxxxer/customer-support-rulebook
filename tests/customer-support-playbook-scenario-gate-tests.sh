#!/usr/bin/env bash
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$REPO_ROOT/customer-support-playbook-scenario/hooks/gate.sh"

export CLAUDE_ROLE=customer-support
CLAUDE_PROJECT_DIR="$(mktemp -d)"
export CLAUDE_PROJECT_DIR
git -C "$CLAUDE_PROJECT_DIR" init -q

pass_count=0
fail_count=0

run_case() {
  local name="$1"
  local expect_deny="$2"
  local payload="$3"

  local output
  output=$(echo "$payload" | bash "$GATE" 2>/dev/null)
  local exit_code=$?

  local denied=0
  if echo "$output" | grep -q '"permissionDecision": "deny"'; then
    denied=1
  fi

  local ok=0
  if [ "$expect_deny" = "exit2" ]; then
    if [ "$exit_code" -eq 2 ]; then
      ok=1
    fi
  elif [ "$expect_deny" = "1" ]; then
    if [ "$denied" -eq 1 ] && [ "$exit_code" -eq 0 ]; then
      ok=1
    fi
  else
    if [ "$denied" -eq 0 ] && [ "$exit_code" -eq 0 ]; then
      ok=1
    fi
  fi

  if [ "$ok" -eq 1 ]; then
    echo "PASS: $name"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $name (exit_code=$exit_code output=$output)"
    fail_count=$((fail_count + 1))
  fi
}

FULL_CONTENT='## Scenario: Refund request\ntrigger: customer requests refund\ndecision criteria: order within 30 days\nscript: "We can process your refund."\nescalation condition: if unresolved after L1, route to L2'

full_payload=$(python3 -c "
import json
print(json.dumps({
    'tool_name': 'Write',
    'tool_input': {
        'file_path': 'customer-support/handbook.md',
        'content': '''$FULL_CONTENT'''
    }
}))
")

run_case "full-pass" "0" "$full_payload"

make_payload_missing() {
  local content="$1"
  python3 -c "
import json, sys
print(json.dumps({
    'tool_name': 'Write',
    'tool_input': {
        'file_path': 'customer-support/handbook.md',
        'content': sys.argv[1]
    }
}))
" "$content"
}

# missing trigger/scenario facet (but keep 'scenario' marker word absent too - use playbook marker instead)
missing_trigger=$(make_payload_missing "## Playbook
decision criteria: order within 30 days
script: we can process your refund
escalation condition: route to L2")
run_case "deny-missing-trigger-or-scenario" "1" "$missing_trigger"

missing_decision=$(make_payload_missing "## Scenario: Refund request
trigger: customer requests refund
script: we can process your refund
escalation condition: route to L2")
run_case "deny-missing-decision-criteria" "1" "$missing_decision"

missing_script=$(make_payload_missing "## Scenario: Refund request
trigger: customer requests refund
decision criteria: order within 30 days
escalation condition: route to L2")
run_case "deny-missing-script-or-response" "1" "$missing_script"

missing_escalation=$(make_payload_missing "## Scenario: Refund request
trigger: customer requests refund
decision criteria: order within 30 days
script: we can process your refund")
run_case "deny-missing-escalation-condition" "1" "$missing_escalation"

# no marker present at all -> pass (not applicable)
no_marker=$(make_payload_missing "This document has no relevant markers at all, just prose.")
run_case "no-marker-pass" "0" "$no_marker"

# kill switch bypass
kill_switch_payload="$missing_escalation"
kill_output=$(CUSTOMER_SUPPORT_PLAYBOOK_SCENARIO_GATE_OFF=1 bash -c "echo '$kill_switch_payload' | bash '$GATE'" 2>/dev/null)
kill_exit=$?
if [ "$kill_exit" -eq 0 ] && ! echo "$kill_output" | grep -q '"permissionDecision": "deny"'; then
  echo "PASS: kill-switch-bypass"
  pass_count=$((pass_count + 1))
else
  echo "FAIL: kill-switch-bypass (exit_code=$kill_exit output=$kill_output)"
  fail_count=$((fail_count + 1))
fi

# malformed JSON
malformed_output=$(echo 'not json' | bash "$GATE" 2>/dev/null)
malformed_exit=$?
if [ "$malformed_exit" -eq 2 ]; then
  echo "PASS: malformed-json-exit2"
  pass_count=$((pass_count + 1))
else
  echo "FAIL: malformed-json-exit2 (exit_code=$malformed_exit)"
  fail_count=$((fail_count + 1))
fi

# non-Write/Edit/MultiEdit passthrough
other_tool_payload=$(python3 -c "
import json
print(json.dumps({'tool_name': 'Read', 'tool_input': {'file_path': 'customer-support/handbook.md'}}))
")
run_case "non-write-edit-multiedit-passthrough" "0" "$other_tool_payload"

echo ""
echo "Summary: $pass_count passed, $fail_count failed"
if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
exit 0
