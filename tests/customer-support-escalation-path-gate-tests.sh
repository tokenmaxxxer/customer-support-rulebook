#!/usr/bin/env bash
set -u

export CLAUDE_ROLE=customer-support
CLAUDE_PROJECT_DIR="$(mktemp -d)"
git -C "$CLAUDE_PROJECT_DIR" init -q
export CLAUDE_PROJECT_DIR

GATE="customer-support-escalation-path/hooks/gate.sh"

pass=0
fail=0

run_case() {
  local name="$1" expect_deny="$2" payload="$3"
  local out
  out="$(echo "$payload" | bash "$GATE" 2>/dev/null)"
  local code=$?

  if [ "$expect_deny" = "1" ]; then
    if echo "$out" | grep -q '"permissionDecision": *"deny"'; then
      echo "PASS: $name"
      pass=$((pass+1))
    else
      echo "FAIL: $name (expected deny, got: $out / exit $code)"
      fail=$((fail+1))
    fi
  else
    if [ -z "$out" ] && [ "$code" -eq 0 ]; then
      echo "PASS: $name"
      pass=$((pass+1))
    else
      echo "FAIL: $name (expected pass, got: $out / exit $code)"
      fail=$((fail+1))
    fi
  fi
}

FULL_CONTENT='## Escalation Path\n\nTier 1: trigger is unresolved after 1h, owner: Support Team Lead, timeout: 30m.'

full_payload=$(jq -n --arg c "$FULL_CONTENT" '{tool_name:"Write", tool_input:{file_path:"customer-support/handbook.md", content:$c}}')
run_case "full-pass" 0 "$full_payload"

no_trigger=$(jq -n --arg c "## Escalation Path\n\nowner: Support Team Lead, timeout: 30m." '{tool_name:"Write", tool_input:{file_path:"customer-support/handbook.md", content:$c}}')
run_case "deny-missing-trigger" 1 "$no_trigger"

no_owner=$(jq -n --arg c "## Escalation Path\n\ntrigger is unresolved after 1h, timeout: 30m." '{tool_name:"Write", tool_input:{file_path:"customer-support/handbook.md", content:$c}}')
run_case "deny-missing-owner" 1 "$no_owner"

no_timeout=$(jq -n --arg c "## Escalation Path\n\ntrigger is unresolved after 1h, owner: Support Team Lead." '{tool_name:"Write", tool_input:{file_path:"customer-support/handbook.md", content:$c}}')
run_case "deny-missing-timeout" 1 "$no_timeout"

out=$(CUSTOMER_SUPPORT_ESCALATION_PATH_GATE_OFF=1 bash -c 'echo "not json" | bash '"$GATE" 2>/dev/null)
code=$?
if [ -z "$out" ] && [ "$code" -eq 0 ]; then
  echo "PASS: kill-switch"
  pass=$((pass+1))
else
  echo "FAIL: kill-switch (got: $out / exit $code)"
  fail=$((fail+1))
fi

malformed_out=$(echo "not json" | bash "$GATE" 2>/dev/null)
malformed_code=$?
if [ "$malformed_code" -eq 2 ]; then
  echo "PASS: malformed-json"
  pass=$((pass+1))
else
  echo "FAIL: malformed-json (exit $malformed_code)"
  fail=$((fail+1))
fi

read_payload=$(jq -n '{tool_name:"Read", tool_input:{file_path:"customer-support/handbook.md"}}')
run_case "non-write-tool" 0 "$read_payload"

echo ""
echo "passed=$pass failed=$fail"
if [ "$fail" -gt 0 ]; then
  exit 1
fi
exit 0
