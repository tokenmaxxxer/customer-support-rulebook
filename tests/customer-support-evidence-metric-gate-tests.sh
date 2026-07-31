#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GATE="$REPO_ROOT/customer-support-evidence-metric/hooks/gate.sh"

export CLAUDE_ROLE=customer-support
TMP_PROJECT_DIR="$(mktemp -d)"
export CLAUDE_PROJECT_DIR="$TMP_PROJECT_DIR"
git -C "$TMP_PROJECT_DIR" init -q

cleanup() {
  rm -rf "$TMP_PROJECT_DIR"
}
trap cleanup EXIT

pass_count=0
fail_count=0

run_case() {
  local name="$1"
  local expect_deny="$2"
  local payload_json="$3"

  local output
  output="$(echo "$payload_json" | CUSTOMER_SUPPORT_EVIDENCE_METRIC_GATE_OFF="${CUSTOMER_SUPPORT_EVIDENCE_METRIC_GATE_OFF:-}" bash "$GATE" 2>"$TMP_PROJECT_DIR/stderr_capture")"
  local exit_code=$?

  local denied="false"
  if echo "$output" | grep -q '"permissionDecision": *"deny"'; then
    denied="true"
  fi

  local ok="false"
  if [ "$expect_deny" = "deny" ] && [ "$denied" = "true" ] && [ "$exit_code" -eq 0 ]; then
    ok="true"
  elif [ "$expect_deny" = "pass" ] && [ "$denied" = "false" ] && [ "$exit_code" -eq 0 ]; then
    ok="true"
  elif [ "$expect_deny" = "exit2" ] && [ "$exit_code" -eq 2 ]; then
    ok="true"
  fi

  if [ "$ok" = "true" ]; then
    echo "PASS: $name"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $name (exit=$exit_code output=$output)"
    fail_count=$((fail_count + 1))
  fi
}

full_pass_payload='{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "customer-support/handbook.md",
    "content": "This procedure aims to raise CSAT by resolving tickets faster."
  }
}'
run_case "full pass - metric cited" "pass" "$full_pass_payload"

missing_metric_payload='{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "customer-support/handbook.md",
    "content": "This procedure describes how agents should escalate tickets."
  }
}'
run_case "deny - no evidence metric present" "deny" "$missing_metric_payload"

fcr_payload='{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "docs/issue-10/reports/customer-support.md",
    "new_string": "We expect this change to improve First Contact Resolution."
  }
}'
run_case "full pass - FCR synonym via Edit" "pass" "$fcr_payload"

sla_payload='{
  "tool_name": "MultiEdit",
  "tool_input": {
    "file_path": "docs/issue-10/reports/customer-support.md",
    "edits": [
      {"new_string": "no metric here"},
      {"new_string": "but SLA-adherence should improve"}
    ]
  }
}'
run_case "full pass - sla-adherence via MultiEdit join" "pass" "$sla_payload"

kill_switch_payload="$missing_metric_payload"
CUSTOMER_SUPPORT_EVIDENCE_METRIC_GATE_OFF=1 run_case "kill switch bypass" "pass" "$kill_switch_payload"

malformed_payload='{ this is not valid json'
run_case "malformed json -> exit 2" "exit2" "$malformed_payload"

non_target_tool_payload='{
  "tool_name": "Read",
  "tool_input": {
    "file_path": "customer-support/handbook.md"
  }
}'
run_case "non Write/Edit/MultiEdit passthrough" "pass" "$non_target_tool_payload"

non_matching_path_payload='{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "customer-support/other.md",
    "content": "no metric mentioned"
  }
}'
run_case "non-matching path passthrough" "pass" "$non_matching_path_payload"

echo "----"
echo "Passed: $pass_count, Failed: $fail_count"

if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
exit 0
