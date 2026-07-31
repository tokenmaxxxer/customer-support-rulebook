#!/usr/bin/env bash
# Standalone tests for customer-support-five-whys/hooks/gate.sh
# Run: bash tests/customer-support-five-whys-gate-tests.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$REPO_ROOT/customer-support-five-whys/hooks/gate.sh"

export CLAUDE_ROLE=customer-support

TMP_PROJECT_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_PROJECT_DIR"' EXIT
git -C "$TMP_PROJECT_DIR" init -q
export CLAUDE_PROJECT_DIR="$TMP_PROJECT_DIR"

pass_count=0
fail_count=0

run_case() {
  local name="$1"
  local expect_deny="$2"
  local payload_json="$3"

  local output
  output=$(echo "$payload_json" | bash "$GATE" 2>/dev/null)
  local exit_code=$?

  local denied=0
  if echo "$output" | grep -q '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"'; then
    denied=1
  fi

  if [ "$expect_deny" = "2" ]; then
    if [ "$exit_code" -eq 2 ]; then
      echo "PASS: $name"
      pass_count=$((pass_count + 1))
    else
      echo "FAIL: $name (expected exit 2, got exit $exit_code)"
      fail_count=$((fail_count + 1))
    fi
    return
  fi

  if [ "$denied" = "$expect_deny" ]; then
    echo "PASS: $name"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $name (expected deny=$expect_deny, got deny=$denied, exit=$exit_code, output=$output)"
    fail_count=$((fail_count + 1))
  fi
}

# Fixture note: multi-cause 5-whys blocks (branching into unrelated causes)
# must route to product-discovery per §2.5 — this is a directive-level
# judgment call this gate script does not and cannot check (shape/presence
# only).
FULL_PASS_CONTENT='## Scenario D: recurring login timeout

This is a repeat inbound pattern.

5-whys check:
1. Why are customers hitting this?
2. Why does documentation not prevent it?
3. Why has this not been fixed already?
4. Why is a workaround not sufficient?
5. Why would this require a product change?

Decision: keep as support-side scenario.'

FULL_PASS_PAYLOAD=$(jq -n --arg fp "customer-support/handbook.md" --arg c "$FULL_PASS_CONTENT" \
  '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}')
run_case "full-pass: recurring + 5-whys label + 5 questions" 0 "$FULL_PASS_PAYLOAD"

MISSING_LABEL_CONTENT='## Scenario D: recurring login timeout

This is a repeat inbound pattern.

1. Why are customers hitting this?
2. Why does documentation not prevent it?
3. Why has this not been fixed already?
4. Why is a workaround not sufficient?
5. Why would this require a product change?

Decision: keep as support-side scenario.'

MISSING_LABEL_PAYLOAD=$(jq -n --arg fp "customer-support/handbook.md" --arg c "$MISSING_LABEL_CONTENT" \
  '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}')
run_case "deny: recurring present, no 5-whys label text" 1 "$MISSING_LABEL_PAYLOAD"

FEW_QUESTIONS_CONTENT='## Scenario D: recurring login timeout

This is a repeat inbound pattern. 5-whys check:

1. Why are customers hitting this?
2. Why does documentation not prevent it?

Decision: keep as support-side scenario.'

FEW_QUESTIONS_PAYLOAD=$(jq -n --arg fp "customer-support/handbook.md" --arg c "$FEW_QUESTIONS_CONTENT" \
  '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}')
run_case "deny: recurring + 5-whys text but fewer than 5 questions" 1 "$FEW_QUESTIONS_PAYLOAD"

NO_RECURRING_CONTENT='## Scenario A: password reset

Standard one-off ticket. Handle per macro and close.'

NO_RECURRING_PAYLOAD=$(jq -n --arg fp "customer-support/handbook.md" --arg c "$NO_RECURRING_CONTENT" \
  '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}')
run_case "pass: no repeat/recurring language, gate does not fire" 0 "$NO_RECURRING_PAYLOAD"

KILL_SWITCH_PAYLOAD=$(jq -n --arg fp "customer-support/handbook.md" --arg c "$MISSING_LABEL_CONTENT" \
  '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}')
CUSTOMER_SUPPORT_FIVE_WHYS_GATE_OFF=1 bash -c '
  output=$(echo "'"$KILL_SWITCH_PAYLOAD"'" | bash "'"$GATE"'")
  exit_code=$?
  if [ "$exit_code" -eq 0 ] && [ -z "$output" ]; then
    echo "PASS: kill-switch bypass"
    exit 0
  else
    echo "FAIL: kill-switch bypass (exit=$exit_code output=$output)"
    exit 1
  fi
'
if [ $? -eq 0 ]; then
  pass_count=$((pass_count + 1))
else
  fail_count=$((fail_count + 1))
fi

MALFORMED_JSON='not json at all'
output=$(echo "$MALFORMED_JSON" | bash "$GATE" 2>/dev/null)
exit_code=$?
if [ "$exit_code" -eq 2 ]; then
  echo "PASS: malformed JSON exits 2"
  pass_count=$((pass_count + 1))
else
  echo "FAIL: malformed JSON (expected exit 2, got $exit_code)"
  fail_count=$((fail_count + 1))
fi

NON_WRITE_PAYLOAD=$(jq -n --arg fp "customer-support/handbook.md" --arg c "$MISSING_LABEL_CONTENT" \
  '{tool_name:"Read", tool_input:{file_path:$fp, content:$c}}')
run_case "pass: non-Write/Edit/MultiEdit tool passthrough" 0 "$NON_WRITE_PAYLOAD"

echo ""
echo "Summary: $pass_count passed, $fail_count failed"
if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
exit 0
