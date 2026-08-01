#!/usr/bin/env bash
set -u
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$REPO_ROOT/tests/lib/harness.sh"
harness_init
GATE="$REPO_ROOT/customer-support-five-whys/hooks/five-whys-gate.sh"

FULL_PASS="Recurring pattern: same refund complaint.
5-whys:
Why did the refund fail?
Why was the policy misapplied?
Why was the agent untrained on this case?
Why did onboarding skip this scenario?
Why does the playbook lack this entry?
Hand off to product-discovery."
run_case "full-pass" pass "$(make_payload Write customer-support/handbook.md "$FULL_PASS")"

NO_LABEL="Recurring pattern: same refund complaint.
Why did the refund fail?
Why was the policy misapplied?
Why was the agent untrained on this case?
Why did onboarding skip this scenario?
Why does the playbook lack this entry?
Hand off to product-discovery."
run_case "deny-missing-5-whys-label" deny "$(make_payload Write customer-support/handbook.md "$NO_LABEL")"

FEW_QUESTIONS="Recurring pattern: same refund complaint.
5-whys:
Why did the refund fail?
Why was the policy misapplied?
Hand off to product-discovery."
run_case "deny-fewer-than-5-questions" deny "$(make_payload Write customer-support/handbook.md "$FEW_QUESTIONS")"

run_case "no-marker-pass" pass "$(make_payload Write customer-support/handbook.md "This is a one-off issue with no pattern of any kind.")"

kill_out="$(printf '%s' "$(make_payload Write customer-support/handbook.md "$NO_LABEL")" | CUSTOMER_SUPPORT_FIVE_WHYS_GATE_OFF=1 bash "$GATE" 2>/dev/null)"
kill_code=$?
if [ "$kill_code" -eq 0 ] && [ -z "$kill_out" ]; then
  echo "PASS: kill-switch-on"; pass_count=$((pass_count+1))
else
  echo "FAIL: kill-switch-on (exit=$kill_code out=$kill_out)"; fail_count=$((fail_count+1))
fi

printf '%s' "$(make_payload Write customer-support/handbook.md "$NO_LABEL")" | CUSTOMER_SUPPORT_FIVE_WHYS_GATE_OFF=maybe bash "$GATE" >/dev/null 2>&1
unrec_code=$?
if [ "$unrec_code" -eq 2 ]; then
  echo "PASS: kill-switch-unrecognized-value-stays-active"; pass_count=$((pass_count+1))
else
  echo "FAIL: kill-switch-unrecognized-value-stays-active (exit=$unrec_code)"; fail_count=$((fail_count+1))
fi

for bad in "not json" "" "[1,2,3]"; do
  printf '%s' "$bad" | bash "$GATE" >/dev/null 2>&1
  code=$?
  if [ "$code" -eq 2 ]; then
    echo "PASS: malformed-json(${bad:-empty})"; pass_count=$((pass_count+1))
  else
    echo "FAIL: malformed-json(${bad:-empty}) (exit=$code)"; fail_count=$((fail_count+1))
  fi
done

run_case "non-write-edit-multiedit-passthrough" pass "$(make_payload Read customer-support/handbook.md "")"

seed_file "customer-support/handbook.md" "OLDMARK pattern: same refund complaint.
OLDMARK
Why did the refund fail?
Why was the policy misapplied?
Why was the agent untrained on this case?
Why did onboarding skip this scenario?
Why does the playbook lack this entry?"
edit_payload="$(make_edit_payload customer-support/handbook.md "OLDMARK" "Recurring" true)"
run_case "edit-replace-all-true-multi-occurrence" deny "$edit_payload"

seed_file "customer-support/handbook.md" "FIRSTMARK pattern: same refund complaint.
SECONDMARK
Why did the refund fail?
Why was the policy misapplied?
Why was the agent untrained on this case?
Why did onboarding skip this scenario?
Why does the playbook lack this entry?"
multi_payload="$(make_multiedit_payload customer-support/handbook.md \
  "FIRSTMARK" "Recurring" true \
  "SECONDMARK" "5-whys:" false)"
run_case "multiedit-mixed-replace-all" pass "$multi_payload"

abs_path="$CLAUDE_PROJECT_DIR/customer-support/handbook.md"
run_case "absolute-path" deny "$(make_payload Write "$abs_path" "$NO_LABEL")"
run_case "dot-prefixed-path" deny "$(make_payload Write "./customer-support/handbook.md" "$NO_LABEL")"

bash_payload="$(make_bash_payload "cat > customer-support/handbook.md <<'EOF'
$NO_LABEL
EOF")"
run_case "bash-write-same-target" deny "$bash_payload"

harness_summary
