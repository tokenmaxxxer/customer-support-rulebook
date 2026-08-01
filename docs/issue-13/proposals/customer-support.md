# Proposal — issue-13: gate A+ remediation (current grade C+)

Phase-1 proposal only. Does not implement; phase 2 opens on Approve per
role-handoff contract v3 s19.

## 1. Precondition check

`tokenmaxxxer/tokenmaxxxer-core` issue-72 (gate-house standard) is landed:
`core/hooks/lib/gate-lib.sh` + `gate-lib.py` +
`docs/handbooks/gate-house-standard.md`, confirmed by direct read
(see scout-brief.md). This proposal adopts that library by reference —
never reimplements it — per the issue's explicit instruction and per
`gate-house-standard.md`'s reference-not-copy rule (`canon-scripts.md`).

## 2. Scope

All seven `customer-support-*/hooks/gate.sh` scripts (phase1-order,
playbook-scenario, evidence-metric, kcs, escalation-path, sla-tier,
five-whys) and their `tests/customer-support-*-gate-tests.sh` suites, plus
`README.md`. Defect inventory: survey.md.

## 3. Structural fixes (reference-adopt `gate-lib.sh`/`.py`)

Each gate's opening sequence changes to:

```bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${<ROLE>_GATE_OFF:-}" || { trap - EXIT; exit 0; }
```

This resolves survey.md item 2 (no trap → fail-open on unexpected abort)
by installing `gate_trap_fail_closed` before anything else can throw, per
`gate-lib.sh`'s own usage contract (it must be the first statement, ahead
of `set -uo pipefail`, so a syntax error two lines down is still caught).
`CLAUDE_PLUGIN_ROOT_CORE` resolution mirrors `compliance-check.sh`'s own
invocation convention (`${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}`)
per scout-brief.md — this repo installs `core` as a sibling plugin
directory, not a vendored copy.

Per-item fix mapping (survey.md → fix):

| Survey item | Fix |
|---|---|
| 1. relative-only path match | Python payload calls `gate_lib.gate_normalize_path(root, file_path)` before applying the existing per-gate regex to the *normalized* root-relative tail; regex changes from anchoring `file_path` directly to anchoring the normalized result. Handles absolute, `./`-prefixed, and relative forms identically. |
| 2. no fail-closed trap | `gate_trap_fail_closed`, installed first (above). |
| 4. deny via stdout+exit0 | Every `missing`-array deny path replaced with `gate_lib`'s stderr+exit-2 convention: bash side calls `gate_deny "<gate-name>" "$reason"` (or the Python payload raises and the bash wrapper relays via `gate_deny`); `permissionDecisionReason` JSON stays as a secondary/compat surface only if a downstream consumer is confirmed to depend on it — check before removing, since none of the seven gates' own tests currently assert on stderr content (survey.md, test suite state). |
| 5. no Edit/MultiEdit reconstruction, replace_all ignored | Any gate whose check needs cross-fragment or whole-document context calls `gate_lib.gate_reconstruct_write(tool, tool_input, current_content)` instead of reading only `new_string`/`edits[].new_string`. `current_content` is read from `file_path` pre-edit (empty string if the file does not yet exist, for `Write`). |
| 6. README ghost files | See §6. |

Kill-switch direction (survey.md's "not a defect" note): each gate's
existing `[[ "${X_OFF:-}" == "1" ]]` already matches
`gate_kill_switch_active`'s fixed on-spelling set
(`1`/`true`/`yes`/`on`, case-insensitive) as a subset. Migration widens
accepted on-spellings to the full set and must not narrow it — regression
check: an existing "only `1` disables" test case must still pass after
migration.

## 4. Semantic check upgrade: substring → section/adjacency

Scout-brief.md's gap line: `gate-lib.sh` does not cover this — it is this
rulebook's own design work, not an adoption.

Current shape (survey.md item 3): each facet check is
`grep -qi '<keyword>'` anywhere in the diff/new-content fragment. Two
independent failure modes conflated as one "keyword present" test:
(a) the keyword appears in a sentence that is not actually the facet's
value (KCS "cause because..." case), and (b) the keyword appears
somewhere in the file with no structural relationship to where the check
expects it (phase1-order's `check_facet`, which accepts a citation marker
anywhere in the same content blob rather than near the claim).

Replacement design — two checks, composed per gate depending on what it
already structures its content by:

**4a. Section-scoped check** (for gates whose target document uses
Markdown headers as field labels — KCS's Cause/Resolution, escalation-path's
per-tier fields, sla-tier's table columns): locate the field via its
heading or table-column boundary, not a whole-document grep. Concretely:
split `current_content` on `^#{1,6}\s` boundaries (or, for sla-tier's
table, on `|`-delimited rows) and apply the keyword/regex check only to
the slice between this field's heading and the next heading at the same
or shallower level. A keyword occurring in a *different* section (e.g. a
"Cause" mention buried in a Resolution section's prose) no longer
satisfies the Cause field's check. This directly fixes the KCS
"because"-in-prose failure mode: `grep -qi 'cause'` becomes "does the
Cause section's own slice contain a value" — an empty or whitespace-only
slice still fails even if the word "cause" appears verbatim as the
heading text itself.

**4b. Adjacency check** (for phase1-order's citation requirement and any
gate pairing a claim keyword with a required citation marker): instead of
"citation marker anywhere in content", require the citation marker
(`scout-brief.md` mention or `https?://` URL) to appear within N lines (or
the same paragraph — a blank-line-delimited block) of the line containing
the facet keyword. Implementation: for each line matching the facet
keyword, scan a fixed window (proposed: same paragraph, falling back to
±3 lines if the paragraph exceeds 20 lines) for the citation pattern;
facet passes only if at least one keyword-line has a citation within its
window. This is the direct fix for `check_facet()`'s current "keyword
anywhere + citation anywhere" independence.

Both checks move into `gate-lib.py`-style Python payloads (matching the
exemplar's existing pattern of JSON/content logic living in Python, bash
staying orchestration-only) but stay **local to each rulebook gate** —
`gate-lib.sh`/`.py` do not define these, per the gap line, so they are
proposed as new functions inside each gate's own inline Python payload
(or a shared local helper file if duplication across the seven gates
exceeds ~2 gates using the identical slice logic — evaluated during
phase-2 implementation, not decided here to avoid over-designing an
abstraction before seeing the actual duplication).

## 5. Mandatory test cases

Per `gate-house-standard.md`'s six mandatory case groups, added to
**every** one of the seven `tests/customer-support-*-gate-tests.sh`
suites where applicable to that gate's tool surface (all seven handle
`Write`/`Edit`/`MultiEdit`; none currently handle `Bash`, so case 6 is
scoped to whichever gates' checked documents are plausible Bash-write
targets — evaluated per-gate in phase 2):

1. `Edit` with `replace_all: true` against a multiply-occurring
   `old_string`.
2. `MultiEdit` with mixed `replace_all: true`/`false` edits in one call.
3. Malformed JSON: truncated, non-object top level, empty payload
   (three sub-cases, not one).
4. Kill-switch set to an unrecognized value (e.g. `"maybe"`) — must
   assert the gate stays **active** (deny/no-op-appropriately, not
   silently disabled).
5. Absolute `file_path` matching the same scope a relative-path fixture
   already matches, plus a `./`-prefixed variant (three path forms
   total per gate).
6. A `Bash`-tool file write reaching the same target a `Write`-tool call
   would hit (where the gate's target surface makes this reachable).

Plus, specific to §4's semantic upgrade: a section/adjacency regression
case per gate — content that contains the keyword in the *wrong* section
or *without* nearby citation, asserted to still deny (this is the case
that would have silently passed under the current substring check and is
the actual bug being fixed; a suite that only re-tests the already-passing
cases does not prove the fix).

Delivery gate (issue-13 requirement 3): full suite green at delivery time,
run via the existing `bash tests/customer-support-*-gate-tests.sh`
invocation pattern, plus `compliance-check.sh` (adopted from core,
scout-brief.md §exemplar) run clean against this repo's `hooks/` — its
output is the delivery evidence, matching the exemplar's own migration
checklist step 5.

## 6. README sync

Remove the three ghost file references
(`record-fields-gate.sh`/`trailer-gate.sh`/`handbook-trigger-gate.sh` —
survey.md item 6, confirmed absent from `customer-support/hooks/`, which
only holds `directive.sh`+`hooks.json`). Add: the seven
`customer-support-*-gate.sh` plugins, their tool-surface triggers
(`Write`/`Edit`/`MultiEdit`, plus `Bash` post-§5), their kill-switch env
var names, and a "sources `core/hooks/lib/gate-lib.sh`, reference not
vendor" line pointing at `gate-house-standard.md`.

## 7. Out of scope for this proposal

- Any change to the seven gates' *content* norms (SLA-tier ITIL-matrix
  traceability, escalation-path named-owner/timeout, evidence-metric
  causal-sentence requirement, five-whys recurring-pattern routing,
  phase1-order artifact ordering, KCS article shape) — those are the
  judgment-level directives already governing this session and are
  unaffected; this proposal only hardens how each gate's *mechanical*
  check for those norms is matched (structure, not substring), not what
  the norms require.
- Migrating any other rulebook repo — issue-72's migration checklist is
  per-repo; this proposal covers only `customer-support-rulebook`.

## 8. Phase-2 acceptance criteria (for the Approve gate, not decided here)

- `compliance-check.sh` clean against `hooks/`.
- All seven gates source `gate-lib.sh` and use `gate_trap_fail_closed`,
  `gate_kill_switch_active`, `gate_deny`, `gate_normalize_path`,
  `gate_reconstruct_write` (the last only where the gate needs
  cross-fragment context).
- All seven test suites carry the six mandatory case groups (§5) plus the
  section/adjacency regression case, full suite green.
- README lists the seven real gates and no ghost files.
