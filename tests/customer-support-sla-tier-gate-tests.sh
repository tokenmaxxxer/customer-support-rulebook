#!/usr/bin/env bash
set -u
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$REPO_ROOT/tests/lib/harness.sh"
harness_init
GATE="$REPO_ROOT/customer-support-sla-tier/hooks/sla-tier-gate.sh"

FULL_CONTENT="| Priority | Impact | Urgency | First Response | Resolution | Escalation Trigger |
|---|---|---|---|---|---|
| P1 | High | High | 15m | 4h | breach in 10m |"
run_case "full-pass" pass "$(make_payload Write customer-support/handbook.md "$FULL_CONTENT")"

run_case "missing-priority" deny "$(make_payload Write customer-support/handbook.md "| Impact | Urgency | First Response | Resolution | Escalation Trigger |")"
run_case "missing-impact" deny "$(make_payload Write customer-support/handbook.md "| Priority | Urgency | First Response | Resolution | Escalation Trigger |")"
run_case "missing-urgency" deny "$(make_payload Write customer-support/handbook.md "| Priority | Impact | First Response | Resolution | Escalation Trigger |")"
run_case "missing-first-response" deny "$(make_payload Write customer-support/handbook.md "| Priority | Impact | Urgency | Resolution | Escalation Trigger |")"
run_case "missing-resolution" deny "$(make_payload Write customer-support/handbook.md "| Priority | Impact | Urgency | First Response | Escalation Trigger |")"
run_case "missing-escalation-trigger" deny "$(make_payload Write customer-support/handbook.md "| Priority | Impact | Urgency | First Response | Resolution |")"

run_case_reason "facet-token-priority" \
  "$(make_payload Write customer-support/handbook.md "| Impact | Urgency | First Response | Resolution | Escalation Trigger |")" \
  "sla-table-column:priority"

# semantic regression: the required words appear only in body prose below an
# unrelated table's header row, never in the header row itself — the
# pre-issue-13 whole-document grep would have passed this.
WRONG_ROW="| Notes | Owner |
|---|---|
| priority impact urgency first response resolution escalation trigger all mentioned here | someone |"
run_case_reason "regression-words-outside-header-row" \
  "$(make_payload Write customer-support/handbook.md "$WRONG_ROW")" \
  "sla-table-column:priority"

kill_out="$(printf '%s' "$(make_payload Write customer-support/handbook.md "no relevant content at all")" | CUSTOMER_SUPPORT_SLA_TIER_GATE_OFF=1 bash "$GATE" 2>/dev/null)"
kill_code=$?
if [ "$kill_code" -eq 0 ] && [ -z "$kill_out" ]; then
  echo "PASS: kill-switch-on"; pass_count=$((pass_count+1))
else
  echo "FAIL: kill-switch-on (exit=$kill_code out=$kill_out)"; fail_count=$((fail_count+1))
fi

printf '%s' "$(make_payload Write customer-support/handbook.md "no relevant content at all")" | CUSTOMER_SUPPORT_SLA_TIER_GATE_OFF=maybe bash "$GATE" >/dev/null 2>&1
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

run_case "non-write-tool-passthrough" pass "$(make_payload Read customer-support/handbook.md "nothing relevant")"

seed_file "customer-support/handbook.md" "| Priority | Impact | Urgency | First Response | Resolution | OLDMARK |
|---|---|---|---|---|---|
| P1 | High | High | 15m | 4h | breach in 10m |"
edit_payload="$(make_edit_payload customer-support/handbook.md "OLDMARK" "Escalation Trigger" true)"
run_case "edit-replace-all-true-multi-occurrence" pass "$edit_payload"

seed_file "customer-support/handbook.md" "| FIRSTMARK | SECONDMARK | Urgency | First Response | Resolution | Escalation Trigger |
|---|---|---|---|---|---|"
multi_payload="$(make_multiedit_payload customer-support/handbook.md \
  "FIRSTMARK" "Priority" true \
  "SECONDMARK" "Impact" false)"
run_case "multiedit-mixed-replace-all" pass "$multi_payload"

abs_path="$CLAUDE_PROJECT_DIR/customer-support/handbook.md"
run_case "absolute-path" deny "$(make_payload Write "$abs_path" "| Priority | Impact | Urgency | First Response | Resolution |")"
run_case "dot-prefixed-path" deny "$(make_payload Write "./customer-support/handbook.md" "| Priority | Impact | Urgency | First Response | Resolution |")"

bash_payload="$(make_bash_payload "cat > customer-support/handbook.md <<'EOF'
| Priority | Impact | Urgency | First Response | Resolution |
EOF")"
run_case "bash-write-same-target" deny "$bash_payload"

harness_summary
