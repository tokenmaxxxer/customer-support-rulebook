#!/usr/bin/env bash
# customer-support-escalation-path gate: requires that any "escalation
# path" section state a trigger, a named owner, and a timeout — checked
# within that section's own slice, not anywhere in the document. Sources
# core's gate-lib.sh (issue-72 gate-house standard), reference-adopt not
# vendor (issue-13).

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${CUSTOMER_SUPPORT_ESCALATION_PATH_GATE_OFF:-}" || { trap - EXIT; exit 0; }

GATE_SEMANTIC_PY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)/customer-support/hooks/lib/semantic.py"
export GATE_SEMANTIC_PY
GATE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
export GATE_PROJECT_DIR
GATE_PAYLOAD="$(cat)"
export GATE_PAYLOAD

python3 <<'PYEOF'
import os, sys, re, importlib.util


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


gate_lib = load("gate_lib", os.environ["GATE_LIB_PY"])
semantic = load("semantic", os.environ["GATE_SEMANTIC_PY"])

GATE_NAME = "customer-support-escalation-path"
DOC_REF = "docs/issue-1/proposals/customer-support.md §2"


def deny(msg):
    print(f"{GATE_NAME}: refused — {msg}", file=sys.stderr)
    sys.exit(2)


raw = os.environ.get("GATE_PAYLOAD", "")
project_dir = os.environ.get("GATE_PROJECT_DIR") or os.getcwd()
event = gate_lib.gate_parse_json_or_deny(raw, deny)
tool = event.get("tool_name")
tool_input = event.get("tool_input") or {}

if tool not in ("Write", "Edit", "MultiEdit", "Bash"):
    sys.exit(0)

PATH_RE = re.compile(r'^customer-support/handbook\.md$|^docs/issue-[0-9]+/reports/customer-support\.md$')


def candidate_paths():
    if tool == "Bash":
        return re.findall(r'[\w./~-]+', tool_input.get("command", ""))
    fp = tool_input.get("file_path")
    return [fp] if isinstance(fp, str) else []


matched = None
for c in candidate_paths():
    norm = gate_lib.gate_normalize_path(project_dir, c)
    if norm is not None and PATH_RE.match(norm):
        matched = c
        break

if matched is None:
    sys.exit(0)

if tool == "Bash":
    deny(f"a Bash-tool command targets {matched}, a file this gate governs, and the "
         "gate cannot reconstruct a Bash-written file's resulting content to check it; "
         "refusing an unverifiable write rather than passing it through")

abs_path = matched if os.path.isabs(matched) else os.path.join(project_dir, matched)
current_content = ""
if os.path.exists(abs_path):
    with open(abs_path, "r", encoding="utf-8", errors="replace") as f:
        current_content = f.read()

content, ok = gate_lib.gate_reconstruct_write(tool, tool_input, current_content)
if not ok:
    deny(f"could not reconstruct the resulting write content for this {tool} call "
         "(e.g. old_string not found in current content); failing closed rather than "
         "checking a partial fragment")

if not re.search(r'(?i)escalation path', content):
    sys.exit(0)

slices = semantic.section_slices(content, r'escalation path')
if slices:
    scoped = "\n".join(s for _heading, s in slices)
else:
    m = re.search(r'(?i)escalation path', content)
    scoped = content[m.end():]

missing = []
if not re.search(r'(?i)trigger', scoped):
    missing.append("escalation-field:trigger")
if not re.search(r'(?i)owner', scoped):
    missing.append("escalation-field:owner")
if not re.search(r'(?i)timeout', scoped):
    missing.append("escalation-field:timeout")

if missing:
    deny("escalation-field write is missing required element(s): " + ",".join(missing) +
         f". Per {DOC_REF}, every phase-2 deliverable/record write must carry: an "
         "escalation path where every tier row/block states a trigger condition, a "
         "named owner (a role/title, not a generic 'the team'), and a timeout, within "
         "the escalation-path section itself.")

sys.exit(0)
PYEOF
