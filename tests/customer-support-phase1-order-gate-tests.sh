#!/usr/bin/env bash
set -u

cd "$(dirname "$0")/.." && repo_root="$(pwd)"
gate="$repo_root/customer-support-phase1-order/hooks/gate.sh"

export CLAUDE_ROLE=customer-support

pass=0
fail=0

run_case() {
  local name="$1" expect_deny="$2" payload="$3"
  shift 3
  local extra_env=("$@")

  local dir
  dir="$(mktemp -d)"
  git -C "$dir" init -q

  # per-test setup hooks are done by caller before invoking run_case via SETUP_DIR var
  if declare -f "setup_${name//-/_}" >/dev/null 2>&1; then
    "setup_${name//-/_}" "$dir"
  fi

  local stderr_file
  stderr_file="$(mktemp)"
  local out
  out="$(env "${extra_env[@]}" CLAUDE_PROJECT_DIR="$dir" bash "$gate" <<<"$payload" 2>"$stderr_file")"
  local exit_code=$?
  local stderr_out
  stderr_out="$(cat "$stderr_file")"
  rm -f "$stderr_file"

  local denied=0
  if echo "$out" | grep -q '"permissionDecision":[[:space:]]*"deny"'; then
    denied=1
  fi

  local ok=1
  if [[ "$expect_deny" == "2" ]]; then
    # malformed JSON case: expect exit code 2
    if [[ "$exit_code" -ne 2 ]]; then
      ok=0
    fi
  else
    if [[ "$denied" -ne "$expect_deny" ]]; then
      ok=0
    fi
  fi

  if [[ -n "${EXPECT_CONTAINS:-}" ]]; then
    if ! echo "$out" | grep -q "$EXPECT_CONTAINS"; then
      ok=0
    fi
  fi

  if [[ "$ok" -eq 1 ]]; then
    echo "PASS: $name"
    pass=$((pass+1))
  else
    echo "FAIL: $name (exit=$exit_code denied=$denied out=$out stderr=$stderr_out)"
    fail=$((fail+1))
  fi

  rm -rf "$dir"
  unset EXPECT_CONTAINS
}

# full-pass
setup_full_pass() {
  local dir="$1"
  mkdir -p "$dir/docs/issue-99/reports/customer-support"
  echo "survey" > "$dir/docs/issue-99/reports/customer-support/survey.md"
  echo "scout brief" > "$dir/docs/issue-99/reports/customer-support/scout-brief.md"
}
EXPECT_CONTAINS='' run_case "full-pass" 0 '{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "docs/issue-99/proposals/customer-support.md",
    "content": "We define the SLA per scout-brief.md section 2. Escalation path is per scout-brief.md. Playbook usage per scout-brief.md. evidence metric defined in scout-brief.md. 5-whys scope bounded per scout-brief.md."
  }
}'

# order-deny: survey missing
setup_order_deny_survey() {
  local dir="$1"
  mkdir -p "$dir/docs/issue-99/reports/customer-support"
  echo "scout brief" > "$dir/docs/issue-99/reports/customer-support/scout-brief.md"
}
EXPECT_CONTAINS='artifact-order:survey' run_case "order-deny-survey" 1 '{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "docs/issue-99/proposals/customer-support.md",
    "content": "plain content no facets"
  }
}'

# order-deny: scout-brief missing
setup_order_deny_scout_brief() {
  local dir="$1"
  mkdir -p "$dir/docs/issue-99/reports/customer-support"
  echo "survey" > "$dir/docs/issue-99/reports/customer-support/survey.md"
}
EXPECT_CONTAINS='artifact-order:scout-brief' run_case "order-deny-scout-brief" 1 '{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "docs/issue-99/proposals/customer-support.md",
    "content": "plain content no facets"
  }
}'

# citation-deny: sla mentioned, no citation
setup_citation_deny_sla() {
  local dir="$1"
  mkdir -p "$dir/docs/issue-99/reports/customer-support"
  echo "survey" > "$dir/docs/issue-99/reports/customer-support/survey.md"
  echo "scout brief" > "$dir/docs/issue-99/reports/customer-support/scout-brief.md"
}
EXPECT_CONTAINS='uncited-claim:sla' run_case "citation-deny-sla" 1 '{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "docs/issue-99/proposals/customer-support.md",
    "content": "We define the SLA with no citation at all."
  }
}'

# kill-switch bypass
run_case "kill-switch-bypass" 0 '{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "docs/issue-99/proposals/customer-support.md",
    "content": "SLA escalation playbook evidence metric 5-whys with nothing cited"
  }
}' CUSTOMER_SUPPORT_PHASE1_ORDER_GATE_OFF=1

# malformed JSON
run_case "malformed-json" 2 'not json at all'

# non-Write/Edit/MultiEdit passthrough
run_case "non-write-passthrough" 0 '{
  "tool_name": "Read",
  "tool_input": {
    "file_path": "docs/issue-99/proposals/customer-support.md"
  }
}'

echo ""
echo "Summary: $pass passed, $fail failed"
if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
exit 0
