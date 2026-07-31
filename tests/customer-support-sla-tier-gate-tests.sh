#!/usr/bin/env bash
# Tests for customer-support-sla-tier gate.sh (issue-10).
# SLA-tier table gate (issue-10).

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$REPO_ROOT/customer-support-sla-tier/hooks/gate.sh"

export CLAUDE_ROLE=customer-support
export CLAUDE_PROJECT_DIR
CLAUDE_PROJECT_DIR="$(mktemp -d)"
git -C "$CLAUDE_PROJECT_DIR" init -q

pass_count=0
fail_count=0

run_case() {
  local name="$1"
  local expect_deny="$2"
  local payload_json="$3"

  local out
  out="$(echo "$payload_json" | bash "$GATE" 2>/dev/null)"
  local code=$?

  if [ "$expect_deny" = "1" ]; then
    if echo "$out" | grep -q '"permissionDecision":"deny"'; then
      echo "PASS: $name"
      pass_count=$((pass_count+1))
    else
      echo "FAIL: $name (expected deny, got: $out)"
      fail_count=$((fail_count+1))
    fi
  else
    if [ -z "$out" ] && [ "$code" -eq 0 ]; then
      echo "PASS: $name"
      pass_count=$((pass_count+1))
    else
      echo "FAIL: $name (expected empty/pass, got out='$out' code=$code)"
      fail_count=$((fail_count+1))
    fi
  fi
}

FULL_CONTENT='| Priority | Impact | Urgency | First Response | Resolution | Escalation Trigger |'

build_payload() {
  local content="$1"
  jq -n --arg content "$content" \
    '{tool_name: "Write", tool_input: {file_path: "customer-support/handbook.md", content: $content}}'
}

# full-pass case
run_case "full-pass" 0 "$(build_payload "$FULL_CONTENT")"

# deny cases: remove each required token one at a time
run_case "missing-priority" 1 "$(build_payload '| Impact | Urgency | First Response | Resolution | Escalation Trigger |')"
run_case "missing-impact" 1 "$(build_payload '| Priority | Urgency | First Response | Resolution | Escalation Trigger |')"
run_case "missing-urgency" 1 "$(build_payload '| Priority | Impact | First Response | Resolution | Escalation Trigger |')"
run_case "missing-first-response" 1 "$(build_payload '| Priority | Impact | Urgency | Resolution | Escalation Trigger |')"
run_case "missing-resolution" 1 "$(build_payload '| Priority | Impact | Urgency | First Response | Escalation Trigger |')"
run_case "missing-escalation-trigger" 1 "$(build_payload '| Priority | Impact | Urgency | First Response | Resolution |')"

# verify facet tokens present in the denial reasons
check_facet() {
  local facet="$1"
  local payload="$2"
  local out
  out="$(echo "$payload" | bash "$GATE" 2>/dev/null)"
  if echo "$out" | grep -q "$facet"; then
    echo "PASS: facet token $facet present"
    pass_count=$((pass_count+1))
  else
    echo "FAIL: facet token $facet missing from: $out"
    fail_count=$((fail_count+1))
  fi
}

check_facet "sla-table-column:priority" "$(build_payload '| Impact | Urgency | First Response | Resolution | Escalation Trigger |')"
check_facet "sla-table-column:impact" "$(build_payload '| Priority | Urgency | First Response | Resolution | Escalation Trigger |')"
check_facet "sla-table-column:urgency" "$(build_payload '| Priority | Impact | First Response | Resolution | Escalation Trigger |')"
check_facet "sla-table-column:first-response" "$(build_payload '| Priority | Impact | Urgency | Resolution | Escalation Trigger |')"
check_facet "sla-table-column:resolution" "$(build_payload '| Priority | Impact | Urgency | First Response | Escalation Trigger |')"
check_facet "sla-table-column:escalation-trigger" "$(build_payload '| Priority | Impact | Urgency | First Response | Resolution |')"

# kill-switch case
CUSTOMER_SUPPORT_SLA_TIER_GATE_OFF=1 run_case "kill-switch" 0 "$(build_payload 'no relevant content at all')"

# malformed-JSON case (direct check, not via run_case)
malformed_out="$(echo "not json" | bash "$GATE" 2>/dev/null)"
malformed_code=$?
if [ "$malformed_code" -eq 2 ]; then
  echo "PASS: malformed-json exits 2"
  pass_count=$((pass_count+1))
else
  echo "FAIL: malformed-json expected exit 2, got $malformed_code"
  fail_count=$((fail_count+1))
fi

# non-Write/Edit/MultiEdit tool_name case
read_payload=$(jq -n '{tool_name: "Read", tool_input: {file_path: "customer-support/handbook.md", content: "nothing relevant"}}')
run_case "non-write-tool-passthrough" 0 "$read_payload"

echo ""
echo "Summary: $pass_count passed, $fail_count failed"

if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
exit 0
