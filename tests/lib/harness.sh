#!/usr/bin/env bash
# Shared test harness for the customer-support-*-gate-tests.sh suites
# (issue-13). Post-migration deny convention is stderr + exit 2
# (gate-lib.sh's gate_deny), not the pre-migration stdout-JSON + exit-0
# shape, so every suite's assertion logic collapsed to the same two
# checks — centralized here since all seven suites need it identically.
set -u

pass_count=0
fail_count=0

# Every gate sources gate-lib.sh from CLAUDE_PLUGIN_ROOT_CORE (falling back
# to a sibling "../../core" checkout, per gate.sh's own resolution). Tests
# run against a real gate-lib.sh, never a stub, so this must resolve to an
# actual tokenmaxxxer-core checkout — set CLAUDE_PLUGIN_ROOT_CORE yourself
# if this repo is not checked out next to tokenmaxxxer-core on disk.
if [ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] || [ ! -f "${CLAUDE_PLUGIN_ROOT_CORE}/hooks/lib/gate-lib.sh" ]; then
  for c in "/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core" \
           "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../tokenmaxxxer-core/core" 2>/dev/null && pwd -P)"; do
    if [ -n "$c" ] && [ -f "$c/hooks/lib/gate-lib.sh" ]; then
      CLAUDE_PLUGIN_ROOT_CORE="$c"
      break
    fi
  done
fi
if [ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] || [ ! -f "${CLAUDE_PLUGIN_ROOT_CORE}/hooks/lib/gate-lib.sh" ]; then
  echo "harness.sh: cannot find core/hooks/lib/gate-lib.sh — set CLAUDE_PLUGIN_ROOT_CORE to a tokenmaxxxer-core checkout before running these tests" >&2
  exit 1
fi
export CLAUDE_PLUGIN_ROOT_CORE

harness_init() {
  export CLAUDE_ROLE=customer-support
  CLAUDE_PROJECT_DIR="$(mktemp -d)"
  export CLAUDE_PROJECT_DIR
  git -C "$CLAUDE_PROJECT_DIR" init -q
}

# run_case <name> <expect> <payload>
#   expect: "deny" (exit 2, non-empty stderr) | "pass" (exit 0, empty stdout)
run_case() {
  local name="$1" expect="$2" payload="$3"
  local out err code
  err="$(mktemp)"
  out="$(printf '%s' "$payload" | bash "$GATE" 2>"$err")"
  code=$?
  local errtext
  errtext="$(cat "$err")"
  rm -f "$err"

  local ok=0
  if [ "$expect" = "deny" ]; then
    [ "$code" -eq 2 ] && [ -n "$errtext" ] && ok=1
  else
    [ "$code" -eq 0 ] && [ -z "$out" ] && ok=1
  fi

  if [ "$ok" -eq 1 ]; then
    echo "PASS: $name"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $name (expect=$expect exit_code=$code stdout='$out' stderr='$errtext')"
    fail_count=$((fail_count + 1))
  fi
}

# run_case_reason <name> <payload> <reason-substring>
# deny-case whose stderr must additionally contain a given substring
# (used for the facet-token / regression assertions).
run_case_reason() {
  local name="$1" payload="$2" needle="$3"
  local err code
  err="$(mktemp)"
  printf '%s' "$payload" | bash "$GATE" >/dev/null 2>"$err"
  code=$?
  local errtext
  errtext="$(cat "$err")"
  rm -f "$err"

  if [ "$code" -eq 2 ] && printf '%s' "$errtext" | grep -qF "$needle"; then
    echo "PASS: $name"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $name (exit_code=$code stderr='$errtext' expected substring='$needle')"
    fail_count=$((fail_count + 1))
  fi
}

make_payload() {
  local tool="$1" file_path="$2" content="$3"
  python3 -c "
import json, sys
print(json.dumps({'tool_name': sys.argv[1], 'tool_input': {'file_path': sys.argv[2], 'content': sys.argv[3]}}))
" "$tool" "$file_path" "$content"
}

make_edit_payload() {
  local file_path="$1" old="$2" new="$3" replace_all="$4"
  python3 -c "
import json, sys
print(json.dumps({'tool_name': 'Edit', 'tool_input': {
    'file_path': sys.argv[1], 'old_string': sys.argv[2], 'new_string': sys.argv[3],
    'replace_all': sys.argv[4] == 'true'}}))
" "$file_path" "$old" "$new" "$replace_all"
}

make_multiedit_payload() {
  # args: file_path edit1_old edit1_new edit1_replace_all edit2_old edit2_new edit2_replace_all
  local file_path="$1"
  python3 -c "
import json, sys
fp = sys.argv[1]
edits = []
rest = sys.argv[2:]
for i in range(0, len(rest), 3):
    edits.append({'old_string': rest[i], 'new_string': rest[i+1], 'replace_all': rest[i+2] == 'true'})
print(json.dumps({'tool_name': 'MultiEdit', 'tool_input': {'file_path': fp, 'edits': edits}}))
" "$@"
}

make_bash_payload() {
  local command="$1"
  python3 -c "
import json, sys
print(json.dumps({'tool_name': 'Bash', 'tool_input': {'command': sys.argv[1]}}))
" "$command"
}

seed_file() {
  # seed_file <relative-path-under-project-dir> <content>
  local rel="$1" content="$2"
  mkdir -p "$(dirname "$CLAUDE_PROJECT_DIR/$rel")"
  printf '%s' "$content" > "$CLAUDE_PROJECT_DIR/$rel"
}

harness_summary() {
  echo ""
  echo "Summary: $pass_count passed, $fail_count failed"
  if [ "$fail_count" -gt 0 ]; then
    exit 1
  fi
  exit 0
}
