#!/usr/bin/env bash
set -u
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$REPO_ROOT/tests/lib/harness.sh"
harness_init
GATE="$REPO_ROOT/customer-support-playbook-scenario/hooks/playbook-scenario-gate.sh"

FULL_CONTENT="## Scenario: Refund request
trigger: customer requests refund
decision criteria: order within 30 days
script: We can process your refund.
escalation condition: if unresolved after L1, route to L2"
run_case "full-pass" pass "$(make_payload Write customer-support/handbook.md "$FULL_CONTENT")"

MISSING_TRIGGER="## Playbook
decision criteria: order within 30 days
script: we can process your refund
escalation condition: route to L2"
run_case "deny-missing-trigger-or-scenario" deny "$(make_payload Write customer-support/handbook.md "$MISSING_TRIGGER")"

MISSING_DECISION="## Scenario: Refund request
trigger: customer requests refund
script: we can process your refund
escalation condition: route to L2"
run_case "deny-missing-decision-criteria" deny "$(make_payload Write customer-support/handbook.md "$MISSING_DECISION")"

MISSING_SCRIPT="## Scenario: Refund request
trigger: customer requests refund
decision criteria: order within 30 days
escalation condition: route to L2"
run_case "deny-missing-script-or-response" deny "$(make_payload Write customer-support/handbook.md "$MISSING_SCRIPT")"

MISSING_ESCALATION="## Scenario: Refund request
trigger: customer requests refund
decision criteria: order within 30 days
script: we can process your refund"
run_case "deny-missing-escalation-condition" deny "$(make_payload Write customer-support/handbook.md "$MISSING_ESCALATION")"

run_case "no-marker-pass" pass "$(make_payload Write customer-support/handbook.md "This document has no relevant markers at all, just prose.")"

# semantic regression: a stray mention of "escalation condition" in unrelated
# prose, never as its own labeled line, must still deny.
PROSE_MENTION="## Scenario: Refund request
trigger: customer requests refund
decision criteria: order within 30 days
script: we can process your refund
note: no escalation condition applies here, handled entirely at L1 in prose"
run_case_reason "regression-prose-mention-is-not-a-field" \
  "$(make_payload Write customer-support/handbook.md "$PROSE_MENTION")" \
  "playbook-element:escalation-condition"

kill_out="$(printf '%s' "$(make_payload Write customer-support/handbook.md "$MISSING_ESCALATION")" | CUSTOMER_SUPPORT_PLAYBOOK_SCENARIO_GATE_OFF=1 bash "$GATE" 2>/dev/null)"
kill_code=$?
if [ "$kill_code" -eq 0 ] && [ -z "$kill_out" ]; then
  echo "PASS: kill-switch-on"; pass_count=$((pass_count+1))
else
  echo "FAIL: kill-switch-on (exit=$kill_code out=$kill_out)"; fail_count=$((fail_count+1))
fi

unrec_code=0
printf '%s' "$(make_payload Write customer-support/handbook.md "$MISSING_ESCALATION")" | CUSTOMER_SUPPORT_PLAYBOOK_SCENARIO_GATE_OFF=maybe bash "$GATE" >/dev/null 2>&1
unrec_code=$?
if [ "$unrec_code" -eq 2 ]; then
  echo "PASS: kill-switch-unrecognized-value-stays-active"; pass_count=$((pass_count+1))
else
  echo "FAIL: kill-switch-unrecognized-value-stays-active (exit=$unrec_code)"; fail_count=$((fail_count+1))
fi

for bad in "not json" "" "[1,2,3]"; do
  code=0
  printf '%s' "$bad" | bash "$GATE" >/dev/null 2>&1
  code=$?
  if [ "$code" -eq 2 ]; then
    echo "PASS: malformed-json(${bad:-empty})"; pass_count=$((pass_count+1))
  else
    echo "FAIL: malformed-json(${bad:-empty}) (exit=$code)"; fail_count=$((fail_count+1))
  fi
done

run_case "non-write-edit-multiedit-passthrough" pass "$(make_payload Read customer-support/handbook.md "")"

seed_file "customer-support/handbook.md" "## Scenario: Refund request
trigger: customer requests refund
OLDMARK
OLDMARK
script: we can process your refund
escalation condition: route to L2"
edit_payload="$(make_edit_payload customer-support/handbook.md "OLDMARK" "decision criteria: order within 30 days" true)"
run_case "edit-replace-all-true-multi-occurrence" pass "$edit_payload"

seed_file "customer-support/handbook.md" "## Scenario: Refund request
FIRSTMARK
FIRSTMARK
SECONDMARK
script: we can process your refund"
multi_payload="$(make_multiedit_payload customer-support/handbook.md \
  "FIRSTMARK" "trigger: customer requests refund" true \
  "SECONDMARK" "decision criteria: order within 30 days" false)"
run_case "multiedit-mixed-replace-all" deny "$multi_payload"

abs_path="$CLAUDE_PROJECT_DIR/customer-support/handbook.md"
run_case "absolute-path" deny "$(make_payload Write "$abs_path" "$MISSING_ESCALATION")"
run_case "dot-prefixed-path" deny "$(make_payload Write "./customer-support/handbook.md" "$MISSING_ESCALATION")"

bash_payload="$(make_bash_payload "cat > customer-support/handbook.md <<'EOF'
$MISSING_ESCALATION
EOF")"
run_case "bash-write-same-target" deny "$bash_payload"

harness_summary
