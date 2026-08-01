#!/usr/bin/env bash
# customer-support-phase1-order gate: requires survey.md + scout-brief.md
# to already exist before a proposal write, and requires every structural
# claim (sla/escalation/playbook/evidence-metric/five-whys) to carry a
# citation adjacent to the claim, not merely present anywhere in the
# document. Sources core's gate-lib.sh (issue-72 gate-house standard),
# reference-adopt not vendor (issue-13).

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${CUSTOMER_SUPPORT_PHASE1_ORDER_GATE_OFF:-}" || { trap - EXIT; exit 0; }

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

GATE_NAME = "customer-support-phase1-order"
DOC_REF = "docs/issue-1/proposals/customer-support.md §1"


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

PATH_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/customer-support\.md$')


def candidate_paths():
    if tool == "Bash":
        return re.findall(r'[\w./~-]+', tool_input.get("command", ""))
    fp = tool_input.get("file_path")
    return [fp] if isinstance(fp, str) else []


matched = None
matched_norm = None
for c in candidate_paths():
    norm = gate_lib.gate_normalize_path(project_dir, c)
    if norm is not None and PATH_RE.match(norm):
        matched, matched_norm = c, norm
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

n = PATH_RE.match(matched_norm).group(1)
survey_path = os.path.join(project_dir, f"docs/issue-{n}/reports/customer-support/survey.md")
scout_path = os.path.join(project_dir, f"docs/issue-{n}/reports/customer-support/scout-brief.md")

missing = []
if not os.path.isfile(survey_path):
    missing.append("artifact-order:survey")
if not os.path.isfile(scout_path):
    missing.append("artifact-order:scout-brief")

CITATION_RE = r'scout-brief\.md|https?://'


def check_facet(keyword_re, facet):
    if re.search(keyword_re, content, re.IGNORECASE):
        if not semantic.adjacency_ok(content, keyword_re, CITATION_RE, window=3):
            missing.append(f"uncited-claim:{facet}")


check_facet(r'sla', 'sla')
check_facet(r'escalation', 'escalation')
check_facet(r'playbook', 'playbook')
check_facet(r'evidence metric', 'evidence-metric')
check_facet(r'5-whys|five whys', 'five-whys')

if missing:
    deny("proposal write is missing required element(s): " + ",".join(missing) +
         f". Per {DOC_REF}, phase-1 proposals must follow the survey→scout-brief→"
         "proposal order and cite every structural claim (sla/escalation/playbook/"
         "evidence-metric/5-whys) to a scout-brief.md or http(s) source within the "
         "same paragraph as the claim, not merely present anywhere in the document.")

sys.exit(0)
PYEOF
