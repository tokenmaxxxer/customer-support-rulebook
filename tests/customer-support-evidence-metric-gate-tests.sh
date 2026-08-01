#!/usr/bin/env bash
set -u
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$REPO_ROOT/tests/lib/harness.sh"
harness_init
GATE="$REPO_ROOT/customer-support-evidence-metric/hooks/evidence-metric-gate.sh"

run_case "full-pass-csat" pass "$(make_payload Write customer-support/handbook.md "This playbook is expected to raise CSAT because faster resolution reduces friction.")"
run_case "full-pass-fcr" pass "$(make_payload Write customer-support/handbook.md "Improves First Contact Resolution by giving agents a decision tree.")"
run_case "deny-no-metric" deny "$(make_payload Write customer-support/handbook.md "This document has no evidence metric mentioned at all.")"

kill_out="$(printf '%s' "$(make_payload Write customer-support/handbook.md "no metric")" | CUSTOMER_SUPPORT_EVIDENCE_METRIC_GATE_OFF=1 bash "$GATE" 2>/dev/null)"
kill_code=$?
if [ "$kill_code" -eq 0 ] && [ -z "$kill_out" ]; then
  echo "PASS: kill-switch-on"; pass_count=$((pass_count+1))
else
  echo "FAIL: kill-switch-on (exit=$kill_code out=$kill_out)"; fail_count=$((fail_count+1))
fi

printf '%s' "$(make_payload Write customer-support/handbook.md "no metric")" | CUSTOMER_SUPPORT_EVIDENCE_METRIC_GATE_OFF=maybe bash "$GATE" >/dev/null 2>&1
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

run_case "non-write-tool-passthrough" pass "$(make_payload Read customer-support/handbook.md "no metric")"

seed_file "customer-support/handbook.md" "OLDMARK OLDMARK expected to move SLA-adherence upward."
edit_payload="$(make_edit_payload customer-support/handbook.md "OLDMARK" "This change is" true)"
run_case "edit-replace-all-true-multi-occurrence" pass "$edit_payload"

seed_file "customer-support/handbook.md" "FIRSTMARK SECONDMARK csat."
multi_payload="$(make_multiedit_payload customer-support/handbook.md \
  "FIRSTMARK" "Expected to raise" true \
  "SECONDMARK" "" false)"
run_case "multiedit-mixed-replace-all" pass "$multi_payload"

abs_path="$CLAUDE_PROJECT_DIR/customer-support/handbook.md"
run_case "absolute-path" deny "$(make_payload Write "$abs_path" "no metric here")"
run_case "dot-prefixed-path" deny "$(make_payload Write "./customer-support/handbook.md" "no metric here")"

bash_payload="$(make_bash_payload "cat > customer-support/handbook.md <<'EOF'
no metric here
EOF")"
run_case "bash-write-same-target" deny "$bash_payload"

harness_summary
