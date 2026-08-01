#!/usr/bin/env bash
set -u
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$REPO_ROOT/tests/lib/harness.sh"
harness_init
GATE="$REPO_ROOT/customer-support-kcs/hooks/kcs-gate.sh"

FULL_CONTENT="## Scenario: Refund request
Issue: customer cannot get refund
Environment: web checkout, orders under 30 days
Resolution: process refund via portal
Cause: policy misconfiguration
Metadata: state=published, maturity=validated"

run_case "full-pass" pass "$(make_payload Write customer-support/handbook.md "$FULL_CONTENT")"

MISSING_ISSUE="## Scenario: Refund request
Environment: web checkout, orders under 30 days
Resolution: process refund via portal
Cause: policy misconfiguration
Metadata: state=published, maturity=validated"
run_case "deny-missing-issue" deny "$(make_payload Write customer-support/handbook.md "$MISSING_ISSUE")"

MISSING_ENV="## Scenario: Refund request
Issue: customer cannot get refund
Resolution: process refund via portal
Cause: policy misconfiguration
Metadata: state=published, maturity=validated"
run_case "deny-missing-environment" deny "$(make_payload Write customer-support/handbook.md "$MISSING_ENV")"

MISSING_RESOLUTION="## Scenario: Refund request
Issue: customer cannot get refund
Environment: web checkout, orders under 30 days
Cause: policy misconfiguration
Metadata: state=published, maturity=validated"
run_case "deny-missing-resolution" deny "$(make_payload Write customer-support/handbook.md "$MISSING_RESOLUTION")"

MISSING_METADATA="## Scenario: Refund request
Issue: customer cannot get refund
Environment: web checkout, orders under 30 days
Resolution: process refund via portal
Cause: policy misconfiguration"
run_case "deny-missing-metadata" deny "$(make_payload Write customer-support/handbook.md "$MISSING_METADATA")"

run_case "no-marker-pass" pass "$(make_payload Write customer-support/handbook.md "This document has no relevant markers at all, just prose.")"

# semantic regression: "cause" only appears inside unrelated prose ("because"),
# never as its own labeled line — the pre-issue-13 substring check would have
# passed this; the section/line-anchor upgrade must still deny it.
BECAUSE_NOT_CAUSE="## Scenario: Refund request
Issue: customer cannot get refund
Environment: web checkout, orders under 30 days
Resolution: process refund via portal
no separate cause because it's covered above
Metadata: state=published, maturity=validated"
run_case_reason "regression-because-is-not-cause" \
  "$(make_payload Write customer-support/handbook.md "$BECAUSE_NOT_CAUSE")" \
  "kcs-element:cause"

# mandatory case group: kill switch on
kill_out="$(printf '%s' "$(make_payload Write customer-support/handbook.md "$MISSING_METADATA")" | CUSTOMER_SUPPORT_KCS_GATE_OFF=1 bash "$GATE" 2>/dev/null)"
kill_code=$?
if [ "$kill_code" -eq 0 ] && [ -z "$kill_out" ]; then
  echo "PASS: kill-switch-on"; pass_count=$((pass_count+1))
else
  echo "FAIL: kill-switch-on (exit=$kill_code out=$kill_out)"; fail_count=$((fail_count+1))
fi

# mandatory case group: kill switch set to an unrecognized value must stay active
unrec_out="$(printf '%s' "$(make_payload Write customer-support/handbook.md "$MISSING_METADATA")" | CUSTOMER_SUPPORT_KCS_GATE_OFF=maybe bash "$GATE" 2>/dev/null)"
unrec_code=$?
if [ "$unrec_code" -eq 2 ]; then
  echo "PASS: kill-switch-unrecognized-value-stays-active"; pass_count=$((pass_count+1))
else
  echo "FAIL: kill-switch-unrecognized-value-stays-active (exit=$unrec_code out=$unrec_out)"; fail_count=$((fail_count+1))
fi

# mandatory case group: malformed JSON (three sub-cases)
for bad in "not json" "" "[1,2,3]"; do
  code_out="$(printf '%s' "$bad" | bash "$GATE" 2>/dev/null)"
  code=$?
  if [ "$code" -eq 2 ]; then
    echo "PASS: malformed-json(${bad:-empty})"; pass_count=$((pass_count+1))
  else
    echo "FAIL: malformed-json(${bad:-empty}) (exit=$code)"; fail_count=$((fail_count+1))
  fi
done

# mandatory case group: non-Write/Edit/MultiEdit passthrough
run_case "non-write-edit-multiedit-passthrough" pass "$(make_payload Read customer-support/handbook.md "")"

# mandatory case group: Edit with replace_all true, multiply-occurring old_string
seed_file "customer-support/handbook.md" "## Scenario: Refund request
Issue: customer cannot get refund
Environment: web checkout, orders under 30 days
Resolution: process refund via portal
OLDMARK
OLDMARK
Metadata: state=published, maturity=validated"
edit_payload="$(make_edit_payload customer-support/handbook.md "OLDMARK" "Cause: policy misconfiguration" true)"
run_case "edit-replace-all-true-multi-occurrence" pass "$edit_payload"

# mandatory case group: MultiEdit with mixed replace_all true/false
seed_file "customer-support/handbook.md" "## Scenario: Refund request
Issue: customer cannot get refund
Environment: web checkout, orders under 30 days
FIRSTMARK
FIRSTMARK
SECONDMARK
Metadata: state=published, maturity=validated"
multi_payload="$(make_multiedit_payload customer-support/handbook.md \
  "FIRSTMARK" "Resolution: process refund via portal" true \
  "SECONDMARK" "Cause: policy misconfiguration" false)"
run_case "multiedit-mixed-replace-all" pass "$multi_payload"

# mandatory case group: absolute and ./-prefixed path forms
abs_path="$CLAUDE_PROJECT_DIR/customer-support/handbook.md"
run_case "absolute-path" deny "$(make_payload Write "$abs_path" "$MISSING_METADATA")"
run_case "dot-prefixed-path" deny "$(make_payload Write "./customer-support/handbook.md" "$MISSING_METADATA")"

# mandatory case group: a Bash-tool write reaching the same governed target
bash_payload="$(make_bash_payload "cat > customer-support/handbook.md <<'EOF'
$MISSING_METADATA
EOF")"
run_case "bash-write-same-target" deny "$bash_payload"

harness_summary
