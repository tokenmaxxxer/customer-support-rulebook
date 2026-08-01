#!/usr/bin/env bash
set -u
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$REPO_ROOT/tests/lib/harness.sh"
harness_init
GATE="$REPO_ROOT/customer-support-phase1-order/hooks/phase1-order-gate.sh"
PROPOSAL_PATH="docs/issue-99/proposals/customer-support.md"

seed_docs() {
  seed_file "docs/issue-99/reports/customer-support/survey.md" "survey"
  seed_file "docs/issue-99/reports/customer-support/scout-brief.md" "scout brief"
}

seed_docs
FULL_PASS="We define the SLA per scout-brief.md section 2.
Escalation path is per scout-brief.md.
Playbook usage per scout-brief.md.
evidence metric defined in scout-brief.md.
5-whys scope bounded per scout-brief.md."
run_case "full-pass" pass "$(make_payload Write "$PROPOSAL_PATH" "$FULL_PASS")"

# order-deny: survey missing (fresh project dir with only scout-brief)
harness_init
GATE="$REPO_ROOT/customer-support-phase1-order/hooks/phase1-order-gate.sh"
seed_file "docs/issue-99/reports/customer-support/scout-brief.md" "scout brief"
run_case_reason "order-deny-survey" \
  "$(make_payload Write "$PROPOSAL_PATH" "plain content no facets")" \
  "artifact-order:survey"

# order-deny: scout-brief missing
harness_init
GATE="$REPO_ROOT/customer-support-phase1-order/hooks/phase1-order-gate.sh"
seed_file "docs/issue-99/reports/customer-support/survey.md" "survey"
run_case_reason "order-deny-scout-brief" \
  "$(make_payload Write "$PROPOSAL_PATH" "plain content no facets")" \
  "artifact-order:scout-brief"

# citation-deny: sla mentioned, no citation
harness_init
GATE="$REPO_ROOT/customer-support-phase1-order/hooks/phase1-order-gate.sh"
seed_docs
run_case_reason "citation-deny-sla" \
  "$(make_payload Write "$PROPOSAL_PATH" "We define the SLA with no citation at all.")" \
  "uncited-claim:sla"

# semantic regression: citation exists somewhere in the document but not
# adjacent to the claim it is supposed to back — a whole-document
# "citation anywhere" check would have passed this.
FAR_CITATION="We define the SLA with no nearby citation at all.

Unrelated paragraph.

Unrelated paragraph.

Unrelated paragraph.

Unrelated paragraph.

Unrelated paragraph.

Unrelated paragraph.

See scout-brief.md for background on something else entirely."
run_case_reason "regression-citation-not-adjacent" \
  "$(make_payload Write "$PROPOSAL_PATH" "$FAR_CITATION")" \
  "uncited-claim:sla"

harness_init
GATE="$REPO_ROOT/customer-support-phase1-order/hooks/phase1-order-gate.sh"
seed_docs

kill_out="$(printf '%s' "$(make_payload Write "$PROPOSAL_PATH" "SLA escalation playbook evidence metric 5-whys with nothing cited")" | CUSTOMER_SUPPORT_PHASE1_ORDER_GATE_OFF=1 bash "$GATE" 2>/dev/null)"
kill_code=$?
if [ "$kill_code" -eq 0 ] && [ -z "$kill_out" ]; then
  echo "PASS: kill-switch-on"; pass_count=$((pass_count+1))
else
  echo "FAIL: kill-switch-on (exit=$kill_code out=$kill_out)"; fail_count=$((fail_count+1))
fi

printf '%s' "$(make_payload Write "$PROPOSAL_PATH" "SLA escalation playbook evidence metric 5-whys with nothing cited")" | CUSTOMER_SUPPORT_PHASE1_ORDER_GATE_OFF=maybe bash "$GATE" >/dev/null 2>&1
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

run_case "non-write-passthrough" pass "$(make_payload Read "$PROPOSAL_PATH" "")"

seed_file "$PROPOSAL_PATH" "We define the OLDMARK per scout-brief.md section 2. OLDMARK."
edit_payload="$(make_edit_payload "$PROPOSAL_PATH" "OLDMARK" "SLA" true)"
run_case "edit-replace-all-true-multi-occurrence" pass "$edit_payload"

seed_file "$PROPOSAL_PATH" "We define the FIRSTMARK per scout-brief.md section 2. SECONDMARK is per scout-brief.md."
multi_payload="$(make_multiedit_payload "$PROPOSAL_PATH" \
  "FIRSTMARK" "SLA" true \
  "SECONDMARK" "Escalation path" false)"
run_case "multiedit-mixed-replace-all" pass "$multi_payload"

abs_path="$CLAUDE_PROJECT_DIR/$PROPOSAL_PATH"
run_case "absolute-path" pass "$(make_payload Write "$abs_path" "$FULL_PASS")"
run_case "dot-prefixed-path" pass "$(make_payload Write "./$PROPOSAL_PATH" "$FULL_PASS")"

bash_payload="$(make_bash_payload "cat > $PROPOSAL_PATH <<'EOF'
plain content no facets
EOF")"
run_case "bash-write-same-target" deny "$bash_payload"

harness_summary
