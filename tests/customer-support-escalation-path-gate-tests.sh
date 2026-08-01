#!/usr/bin/env bash
set -u
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$REPO_ROOT/tests/lib/harness.sh"
harness_init
GATE="$REPO_ROOT/customer-support-escalation-path/hooks/escalation-path-gate.sh"

FULL_CONTENT="## Escalation Path

Tier 1: trigger is unresolved after 1h, owner: Support Team Lead, timeout: 30m."
run_case "full-pass" pass "$(make_payload Write customer-support/handbook.md "$FULL_CONTENT")"

NO_TRIGGER="## Escalation Path

owner: Support Team Lead, timeout: 30m."
run_case "deny-missing-trigger" deny "$(make_payload Write customer-support/handbook.md "$NO_TRIGGER")"

NO_OWNER="## Escalation Path

trigger is unresolved after 1h, timeout: 30m."
run_case "deny-missing-owner" deny "$(make_payload Write customer-support/handbook.md "$NO_OWNER")"

NO_TIMEOUT="## Escalation Path

trigger is unresolved after 1h, owner: Support Team Lead."
run_case "deny-missing-timeout" deny "$(make_payload Write customer-support/handbook.md "$NO_TIMEOUT")"

run_case "no-marker-pass" pass "$(make_payload Write customer-support/handbook.md "no relevant section here")"

# semantic regression: trigger/owner/timeout appear only in an unrelated
# section, never inside the Escalation Path section itself — a whole-
# document grep would have passed this.
WRONG_SECTION="## Escalation Path

Tier 1: escalate promptly.

## Unrelated Notes

trigger: n/a, owner: n/a, timeout: n/a — these do not belong to the escalation path."
run_case_reason "regression-fields-outside-escalation-section" \
  "$(make_payload Write customer-support/handbook.md "$WRONG_SECTION")" \
  "escalation-field:trigger"

kill_out="$(printf '%s' "$(make_payload Write customer-support/handbook.md "$NO_TIMEOUT")" | CUSTOMER_SUPPORT_ESCALATION_PATH_GATE_OFF=1 bash "$GATE" 2>/dev/null)"
kill_code=$?
if [ "$kill_code" -eq 0 ] && [ -z "$kill_out" ]; then
  echo "PASS: kill-switch-on"; pass_count=$((pass_count+1))
else
  echo "FAIL: kill-switch-on (exit=$kill_code out=$kill_out)"; fail_count=$((fail_count+1))
fi

printf '%s' "$(make_payload Write customer-support/handbook.md "$NO_TIMEOUT")" | CUSTOMER_SUPPORT_ESCALATION_PATH_GATE_OFF=maybe bash "$GATE" >/dev/null 2>&1
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

run_case "non-write-tool-passthrough" pass "$(make_payload Read customer-support/handbook.md "")"

seed_file "customer-support/handbook.md" "## Escalation Path

Tier 1: OLDMARK is unresolved after 1h (OLDMARK), owner: Support Team Lead, timeout: 30m."
edit_payload="$(make_edit_payload customer-support/handbook.md "OLDMARK" "trigger" true)"
run_case "edit-replace-all-true-multi-occurrence" pass "$edit_payload"

seed_file "customer-support/handbook.md" "## Escalation Path

Tier 1: FIRSTMARK unresolved after 1h, SECONDMARK: Support Team Lead."
multi_payload="$(make_multiedit_payload customer-support/handbook.md \
  "FIRSTMARK" "trigger" true \
  "SECONDMARK" "owner" false)"
run_case "multiedit-mixed-replace-all" deny "$multi_payload"

abs_path="$CLAUDE_PROJECT_DIR/customer-support/handbook.md"
run_case "absolute-path" deny "$(make_payload Write "$abs_path" "$NO_TIMEOUT")"
run_case "dot-prefixed-path" deny "$(make_payload Write "./customer-support/handbook.md" "$NO_TIMEOUT")"

bash_payload="$(make_bash_payload "cat > customer-support/handbook.md <<'EOF'
$NO_TIMEOUT
EOF")"
run_case "bash-write-same-target" deny "$bash_payload"

harness_summary
